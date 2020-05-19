//+------------------------------------------------------------------+
//|                                              Trading Trainer.mq4 |
//|                                    Copyright 2019, Anwar Minarso |
//|                                  https://github.com/anwarminarso |
//+------------------------------------------------------------------+
#property copyright  "Copyright 2019, Anwar Minarso"
#property link       "https://github.com/anwarminarso"
#property version    "1.00"
#property strict


enum MY_TT_ENUM_TRAILING_METHOD {
   b = 1,   // by extremums of candlesticks
   c = 2,   // by fractals
   d = 3,   // by ATR indicator
   e = 4,   // by Parabolic indicator
   f = 5,   // by MA indicator
   //g = 6,   // by profit %
   i = 7,   // by points
};

input string s1 = "----- General Settings -----";
input int         MagicNumber = 9999;
input double      LotSize = 1;
input int         spread = 8; // slipage
input int         PriceDigit = 5; // Price decimal

input string s4 = "----- Trailing Settings -----";
input bool EnableTrailing                          = false;  // Enable Trailing
input int   TrailingStart                          = 1;  // Minimal profit of trailing stop in points
input int   TrailingStep                           = 1;   // Stop loss movement step
input ENUM_TIMEFRAMES TrailingPeriod               = PERIOD_M1;  // Trailing Period
input MY_TT_ENUM_TRAILING_METHOD TrailingMethod    = e;  // Trailing Method
input color TrailingLabelColor                     = Lime; //Trailing Label Color
input int    TrailingDelta                         = 35;      // Offset from the stop loss calculation level
input int    ATRPeriod                             = 14; // ATR period (for ATR Trailing)
input double SARStep                               = 0.02; // Parabolic SAR Step (for Parabolic Trailing)
input double SARMaximum                            = 0.2; // Parabolic Maximum (for Parabolic Trailing)
input int MAPeriod                                 = 34; // MA period (for MA Trailing)
input ENUM_MA_METHOD MAMethod                      = MODE_SMA; // Averaging method (for MA Trailing)
input ENUM_APPLIED_PRICE MAAppliedPrice            = PRICE_CLOSE; // Price type (for MA Trailing)


int STOPLEVEL = 0;

int chart_ID = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   //spread = MarketInfo(Symbol(), MODE_SPREAD);
   if(IsTesting()) {
      STOPLEVEL = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
      string name;
      int xc = 30;
      int yc = 30;
      
      name = "MY_EA_Win";
      ObjectCreate(chart_ID, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetText(name, name, 10, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc - 5);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc - 5);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE, 214);
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE, 240);
      //ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrWheat);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 0);
      
      name = "MY_EA_BUY_STOP";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Buy Stop", 10, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID,name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID,name, OBJPROP_XSIZE, 70);
      
      name = "MY_EA_PRICE_STOP";
      ObjectCreate(chart_ID, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetText(name, DoubleToStr(0, Digits), 10, "Arial", clrRed);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 72);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 60);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_CENTER);


      name = "MY_EA_SELL_STOP";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Sell Stop", 10, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 134);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID,name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID,name, OBJPROP_XSIZE, 70);
      

      
      yc += 22;
      name = "MY_EA_BUY";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Buy", 14, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID,name, OBJPROP_YSIZE, 30);
      ObjectSetInteger(chart_ID,name, OBJPROP_XSIZE, 70);
      
      name = "MY_EA_PRICE";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "0", 14, "Arial", clrBlue);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 72);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 30);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 60);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_CENTER);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);

      name = "MY_EA_SELL";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Sell", 14, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 134);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID,name, OBJPROP_YSIZE, 30);
      ObjectSetInteger(chart_ID,name, OBJPROP_XSIZE, 70);
      
      yc += 32;
      name = "MY_EA_BUY_LIMIT";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Buy Limit", 10, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID,name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID,name, OBJPROP_XSIZE, 70);
      
      name = "MY_EA_PRICE_LIMIT";
      ObjectCreate(chart_ID, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetText(name, DoubleToStr(0, Digits), 10, "Arial", clrRed);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 72);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 60);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_CENTER);
      
      name = "MY_EA_SELL_LIMIT";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Sell Limit", 10, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 134);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 70);
      
      yc += 22;
      name = "MY_EA_SL_LABEL";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "SL:", 10, "Arial", clrRed);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 20);
      
      
      name = "MY_EA_SL";
      ObjectCreate(chart_ID, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetText(name, DoubleToStr(0, Digits), 10, "Arial", clrRed);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 22);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 70);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_CENTER);
      
      name = "MY_EA_TP_LABEL";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "TP:", 10, "Arial", clrBlue);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 112);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 20);

      name = "MY_EA_TP";
      ObjectCreate(chart_ID, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetText(name, DoubleToStr(0, Digits), 10, "Arial", clrRed);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 134);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 70);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_CENTER);
      
      
      yc += 32;
      
      name = "MY_EA_BALANCE_LABEL";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "Balance:", 10, "Arial", clrBlack);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 70);
      
      
      name = "MY_EA_BALANCE";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "0", 10, "Arial", clrBlueViolet);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 72);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 132);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_LEFT);
      
      yc += 22;
      name = "MY_EA_EQUITY_LABEL";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "Equity:", 10, "Arial", clrBlack);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 70);
      name = "MY_EA_EQUITY";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "0", 10, "Arial", clrBlueViolet);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 72);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 132);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_LEFT);
      
      
      yc += 22;
      name = "MY_EA_BUY_PL_LABEL";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "Buy P/L:", 10, "Arial", clrBlack);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 70);
      name = "MY_EA_BUY_PL";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "0", 10, "Arial", clrBlueViolet);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 72);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 132);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_LEFT);
      
      yc += 22;
      name = "MY_EA_SELL_PL_LABEL";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "Sell P/L:", 10, "Arial", clrBlack);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 70);
      name = "MY_EA_SELL_PL";
      ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetText(name, "0", 10, "Arial", clrBlueViolet);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 72);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, 132);
      ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_LEFT);
      
      
      yc += 32;
      name = "MY_EA_CLOSE_ORDER";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Close All", 10, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID,name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID,name, OBJPROP_XSIZE, 66);
      
      
      name = "MY_EA_MODIFY_ORDER";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Modify All", 10, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 68);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID,name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID,name, OBJPROP_XSIZE, 66);
      
      name = "MY_EA_DELETE_ORDER";
      ObjectCreate(chart_ID, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetText(name, "Delete Pnd", 10, "Arial", clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, xc + 136);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, yc);
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_COLOR, clrGray);
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, 1);
      ObjectSetInteger(chart_ID,name, OBJPROP_YSIZE, 20);
      ObjectSetInteger(chart_ID,name, OBJPROP_XSIZE, 66);
   }
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   string PN = "Event: ";
   for(int i = ObjectsTotal() - 1; i >= 0; i--) {
      string Obj_Name = ObjectName(i);
      if(StringFind(Obj_Name, PN, 0) != -1) {
         ObjectDelete(Obj_Name);
      }
   }
   Comment("");
   return;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   if(IsTesting()) {
      double ask = Ask;
      double bid = Bid;
      
      double ProfitB = 0, ProfitS = 0;
      for(int j = 0; j < OrdersTotal(); j++) {
         if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == true) {
            if((MagicNumber == OrderMagicNumber()) && OrderSymbol() == Symbol()) {
               if(OrderType() == OP_BUY ) {
                  ProfitB += OrderProfit() + OrderSwap() + OrderCommission();
               }
               if(OrderType() == OP_SELL) {
                  ProfitS += OrderProfit() + OrderSwap() + OrderCommission();
               }
            }
         }
      }
      
      string name = "";
      
      name = "MY_EA_PRICE";
      if(ObjectFind(name) != -1)
         ObjectSetText(name, DoubleToStr(ask, PriceDigit), 12, "Arial", clrBlue);
         
      name = "MY_EA_BALANCE";
      if(ObjectFind(name) != -1)
         ObjectSetText(name, formatDouble(AccountBalance(), 2), 10, "Arial", clrBlueViolet);
      name = "MY_EA_EQUITY";
      if(ObjectFind(name) != -1)
         ObjectSetText(name, formatDouble(AccountEquity(), 2), 10, "Arial", clrBlueViolet);
      name = "MY_EA_BUY_PL";
      if(ObjectFind(name) != -1)
         ObjectSetText(name, formatDouble(ProfitB, 2), 10, "Arial", Color(ProfitB >= 0, clrBlue, clrRed));
      name = "MY_EA_SELL_PL";
      if(ObjectFind(name) != -1)
         ObjectSetText(name, formatDouble(ProfitS, 2), 10, "Arial", Color(ProfitS >= 0, clrBlue, clrRed));
         
         
      name = "MY_EA_BUY";
      if(ObjectGetInteger(chart_ID, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(chart_ID, name, OBJPROP_STATE, false);
         double sl = StrToDouble(ObjectGetString(chart_ID, "MY_EA_SL", OBJPROP_TEXT));
         double tp = StrToDouble(ObjectGetString(chart_ID, "MY_EA_TP", OBJPROP_TEXT));
         int ticket = OrderSend(Symbol(), OP_BUY, LotSize, ask, spread, sl, tp, NULL, MagicNumber, 0, clrNONE);
         return;
      }
      name = "MY_EA_BUY_STOP";
      if(ObjectGetInteger(chart_ID, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(chart_ID, name, OBJPROP_STATE, false);
         double price = StrToDouble(ObjectGetString(chart_ID, "MY_EA_PRICE_STOP", OBJPROP_TEXT));
         double sl = StrToDouble(ObjectGetString(chart_ID, "MY_EA_SL", OBJPROP_TEXT));
         double tp = StrToDouble(ObjectGetString(chart_ID, "MY_EA_TP", OBJPROP_TEXT));
         int ticket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, price, spread, sl, tp, NULL, MagicNumber, 0, clrNONE);
         return;
      }
      name = "MY_EA_BUY_LIMIT";
      if(ObjectGetInteger(chart_ID, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(chart_ID, name, OBJPROP_STATE, false);
         double price = StrToDouble(ObjectGetString(chart_ID, "MY_EA_PRICE_LIMIT", OBJPROP_TEXT));
         double sl = StrToDouble(ObjectGetString(chart_ID, "MY_EA_SL", OBJPROP_TEXT));
         double tp = StrToDouble(ObjectGetString(chart_ID, "MY_EA_TP", OBJPROP_TEXT));
         int ticket = OrderSend(Symbol(), OP_BUYLIMIT, LotSize, price, spread, sl, tp, NULL, MagicNumber, 0, clrNONE);
         return;
      }
      name = "MY_EA_SELL";
      if(ObjectGetInteger(0, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(0, name, OBJPROP_STATE, false);
         double sl = StrToDouble(ObjectGetString(chart_ID, "MY_EA_SL", OBJPROP_TEXT));
         double tp = StrToDouble(ObjectGetString(chart_ID, "MY_EA_TP", OBJPROP_TEXT));
         int ticket = OrderSend(Symbol(), OP_SELL, LotSize, bid, spread, sl, tp, NULL, MagicNumber, 0, clrNONE);
         return;
      }
      name = "MY_EA_SELL_STOP";
      if(ObjectGetInteger(chart_ID, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(chart_ID, name, OBJPROP_STATE, false);
         double price = StrToDouble(ObjectGetString(chart_ID, "MY_EA_PRICE_STOP", OBJPROP_TEXT));
         double sl = StrToDouble(ObjectGetString(chart_ID, "MY_EA_SL", OBJPROP_TEXT));
         double tp = StrToDouble(ObjectGetString(chart_ID, "MY_EA_TP", OBJPROP_TEXT));
         int ticket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, price, spread, sl, tp, NULL, MagicNumber, 0, clrNONE);
         return;
      }
      name = "MY_EA_SELL_LIMIT";
      if(ObjectGetInteger(chart_ID, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(chart_ID, name, OBJPROP_STATE, false);
         double price = StrToDouble(ObjectGetString(chart_ID, "MY_EA_PRICE_LIMIT", OBJPROP_TEXT));
         double sl = StrToDouble(ObjectGetString(chart_ID, "MY_EA_SL", OBJPROP_TEXT));
         double tp = StrToDouble(ObjectGetString(chart_ID, "MY_EA_TP", OBJPROP_TEXT));
         int ticket = OrderSend(Symbol(), OP_SELLLIMIT, LotSize, price, spread, sl, tp, NULL, MagicNumber, 0, clrNONE);
         return;
      }
      name = "MY_EA_CLOSE_ORDER";
      if(ObjectGetInteger(chart_ID, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(chart_ID, name, OBJPROP_STATE, false);
         int tot = OrdersTotal() - 1;
         for(int j = tot; j >= 0; j--) {
            if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == true) {
               if((MagicNumber == OrderMagicNumber()) 
                  && OrderSymbol() == Symbol()
                  && OrderType() <= OP_SELL) {
                  if (OrderType()==OP_BUY) {
                     if(!OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet))
                        Print("Order Close error ",GetLastError());
                  }      
                  else if (OrderType()==OP_SELL) {
                     if(!OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet))
                        Print("Order Close error ",GetLastError());
                  }      
                        
               }
            }
         }
         return;
      }
      name = "MY_EA_CANCEL_ORDER";
      if(ObjectGetInteger(chart_ID, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(chart_ID, name, OBJPROP_STATE, false);
         int tot = OrdersTotal() - 1;
         for(int j = tot; j >= 0; j--) {
            if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == true) {
               if((MagicNumber == OrderMagicNumber()) 
                  && OrderSymbol() == Symbol()
                  && OrderType() > OP_SELL) {
                  if (!OrderDelete(OrderTicket(), Violet))
                        Print("Order Delete error ",GetLastError());
                        
               }
            }
         }
         return;
      }
      name = "MY_EA_MODIFY_ORDER";
      if(ObjectGetInteger(chart_ID, name, OBJPROP_STATE) == true) {
         ObjectSetInteger(chart_ID, name, OBJPROP_STATE, false);
         int tot = OrdersTotal() - 1;
         for(int j = tot; j >= 0; j--) {
            if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES) == true) {
               if((MagicNumber == OrderMagicNumber()) 
                  && OrderSymbol() == Symbol()){
                  double sl = StrToDouble(ObjectGetString(chart_ID, "MY_EA_SL", OBJPROP_TEXT));
                  double tp = StrToDouble(ObjectGetString(chart_ID, "MY_EA_TP", OBJPROP_TEXT));
                  if (!OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0, clrViolet))
                        Print("Order Modify error ",GetLastError());
                        
               }
            }
         }
         return;
      }
      if (EnableTrailing)
         doTrailing();
   }
//---
}

void doTrailing() {
   int tot = OrdersTotal();
   double SL   = 0; // Stop Loss
   double OSL  = 0; //Order Stop Loss
   double OOP  = 0; // Order Open Price
   datetime OT = 0; // Order Time
   double OP = 0; // Order Profit/Loss
   
   for(int i = 0; i < tot; i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true) {
         if((MagicNumber == OrderMagicNumber()) && OrderSymbol() == Symbol()) {
            OSL  = OrderStopLoss();
            OOP = OrderOpenPrice();
            OT = OrderOpenTime();
            OP = OrderProfit();
            if(OrderType() == OP_BUY ) {
               SL = MY_EA_SL_BAR(OP_BUY, Bid, OOP);
               if(SL < OOP + TrailingStart * Point) 
                  continue;
                  
               if(SL >= OSL + TrailingStep * Point && (Bid - SL) / Point > STOPLEVEL) {
                  if (!OrderModify(OrderTicket(), OOP, SL, OrderTakeProfit(), 0, Green))
                     Print("OrderModify error ",GetLastError());
                  continue;
               }
            }
            if(OrderType() == OP_SELL) {
               SL = MY_EA_SL_BAR(OP_SELL, Ask, OOP);
               if(SL > OOP - TrailingStart * Point) 
                  continue;
               if((SL <= OSL - TrailingStep * Point || OSL == 0) && (SL - Ask) / Point > STOPLEVEL) {
                  if (!OrderModify(OrderTicket(), OOP, SL, OrderTakeProfit(), 0, Green))
                     Print("OrderModify error ",GetLastError());
                  continue;
               }
            }
         }
      }
   }
}
double MY_EA_SL_BAR(int tip, double price, double OOP) {
   double prc = 0;
   int i;
   switch(TrailingMethod) {
   case 1: // by extremums of candlesticks
      if(tip == OP_BUY) {
         for(i = 1; i < 500; i++) {
            prc = NormalizeDouble(iLow(Symbol(), TrailingPeriod, i) - TrailingDelta * Point, Digits);
            if(prc != 0) if(price - STOPLEVEL * Point > prc) break;
               else prc = 0;
         }
      }
      if(tip == OP_SELL) {
         for(i = 1; i < 500; i++) {
            prc = NormalizeDouble(iHigh(Symbol(), TrailingPeriod, i) + TrailingDelta * Point, Digits);
            if(prc != 0) if(price + STOPLEVEL * Point < prc) break;
               else prc = 0;
         }
      }
      break;

   case 2: // by fractals
      if(tip == OP_BUY) {
         for(i = 1; i < 100; i++) {
            prc = iFractals(Symbol(), TrailingPeriod, MODE_LOWER, i);
            if(prc != 0) {
               prc = NormalizeDouble(prc - TrailingDelta * Point, Digits);
               if(price - STOPLEVEL * Point > prc) break;
            } else prc = 0;
         }
      }
      if(tip == OP_SELL) {
         for(i = 1; i < 100; i++) {
            prc = iFractals(Symbol(), TrailingPeriod, MODE_UPPER, i);
            if(prc != 0) {
               prc = NormalizeDouble(prc + TrailingDelta * Point, Digits);
               if(price + STOPLEVEL * Point < prc) break;
            } else prc = 0;
         }
      }
      break;
   case 3: // by ATR indicator
      if(tip == OP_BUY) {
         prc = NormalizeDouble(Bid - iATR(Symbol(), TrailingPeriod, ATRPeriod, 0) - TrailingDelta * Point, Digits);
      }
      if(tip == OP_SELL) {
         prc = NormalizeDouble(Ask + iATR(Symbol(), TrailingPeriod, ATRPeriod, 0) + TrailingDelta * Point, Digits);
      }
      break;

   case 4: // by Parabolic indicator
      prc = iSAR(Symbol(), TrailingPeriod, SARStep, SARMaximum, 0);
      if(tip == OP_BUY) {
         prc = NormalizeDouble(prc - TrailingDelta * Point, Digits);
         if(price - STOPLEVEL * Point < prc) prc = 0;
      }
      if(tip == OP_SELL) {
         prc = NormalizeDouble(prc + TrailingDelta * Point, Digits);
         if(price + STOPLEVEL * Point > prc) prc = 0;
      }
      break;

   case 5: // by MA indicator
      prc = iMA(Symbol(), TrailingPeriod, MAPeriod, 0, MAMethod, MAAppliedPrice, 0);
      if(tip == OP_BUY) {
         prc = NormalizeDouble(prc - TrailingDelta * Point, Digits);
         if(price - STOPLEVEL * Point < prc) prc = 0;
      }
      if(tip == OP_SELL) {
         prc = NormalizeDouble(prc + TrailingDelta * Point, Digits);
         if(price + STOPLEVEL * Point > prc) prc = 0;
      }
      break;
   //case 6: // % of profit
   //   if(tip == OP_BUY) {
   //      prc = NormalizeDouble(OOP + (price - OOP) / 100 * PercentProfit, Digits);
   //      ARROW("MY_EA_SL_Buy", prc, 4, clrAqua);
   //      DrawLABEL(1, "MY_EA SL Buy", StringConcatenate("SL Buy % ", DoubleToStr(prc, Digits)), 5, 100, TrailingLabelColor);
   //   }
   //   if(tip == OP_SELL) {
   //      prc = NormalizeDouble(OOP - (OOP - price) / 100 * PercentProfit, Digits);
   //      ARROW("MY_EA_SL_Sell", prc, 4, clrRed);
   //      DrawLABEL(1, "MY_EA SL Sell", StringConcatenate("SL Sell % ", DoubleToStr(prc, Digits)), 5, 120, TrailingLabelColor);
   //   }
   //   break;
   default: // by points
      if(tip == OP_BUY) {
         prc = NormalizeDouble(price - TrailingDelta * Point(), Digits);
      }
      if(tip == OP_SELL) {
         prc = NormalizeDouble(price + TrailingDelta * Point(), Digits);
      }
      break;
   }
   return(prc);
}

string formatDouble(double number, int precision, string pcomma=",", string ppoint=".")
{
   double n = MathAbs(number);
   string snum   = DoubleToStr(n, precision);
   int    decp   = StringFind(snum,".",0);
   string sright = StringSubstr(snum,decp+1,precision);
   string sleft  = StringSubstr(snum,0,decp);
   string formated = "";
   string comma    = "";
   
      while (StringLen(sleft)>3)
      {
         int    length = StringLen(sleft);
         string part   = StringSubstr(sleft,length-3,0);
              formated = part+comma+formated;
              comma    = pcomma;
              sleft    = StringSubstr(sleft,0,length-3);
      }
      
      if (sleft!="")   formated = sleft+comma+formated;
      if (precision>0) formated = formated+ppoint+sright;
      
   if (number < 0)
      formated = "-" + formated;   
   return(formated);
}  
color Color(bool P, color a, color b) {
   if(P) return(a);
   return(b);
}