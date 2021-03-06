//+------------------------------------------------------------------+
//|                                               Ichimoku EA v2.mq4 |
//|                                    Copyright 2019, Anwar Minarso |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property description   "Expert Advisor (EA) v2 based on Ichimoku Indicator"
#property description   "Double Swords Warrior Technique"
#property description   "Four strategies: "
#property description   "1. Ideal Strategy"
#property description   "2. Tenkan vs Kijun vs Chikou Strategy"
#property description   "3. Kumo Breakout Strategy"
#property description   "4. Chikou Span Strategy"
#property copyright     "Copyright 2019, Anwar Minarso"
#property link          "https://github.com/anwarminarso"
#property version       "1.01"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int MY_EA_BEARISH = -1;
int MY_EA_CONSOLIDATE = 0;
int MY_EA_BULLISH = 1;
int MY_EA_FUTURE_SIZE = 10;
int MY_EA_KUMO_GROUP = 4;


enum MY_EA_ENUM_TRAILING_METHOD {
   b = 1,   // by extremums of candlesticks
   c = 2,   // by fractals
   d = 3,   // by ATR indicator
   e = 4,   // by Parabolic indicator
   f = 5,   // by MA indicator
   //g = 6,   // by profit %
   i = 7,   // by points
};

input string s1 = "----- General Settings -----";
input double BuyTakeProfit          = 0; // Default TP for Buy
input double BuyStopLoss            = 95; // Default S/L for Buy
input double SellTakeProfit         = 0; // Default TP for Sell
input double SellStopLoss           = 95; // Default S/L for Sell
input double Lots                   = 1; // Lot
input int    maxTrade               = 3; // Max Open Trade (for All Trade)

input string s2 = "----- Ichimoku Settings -----";
input ENUM_TIMEFRAMES    IchimokuTimeFrame = PERIOD_M5; // Ichimoku Time Frame
input int    TenkanSenPeriod  = 9;  // Tenkan Sen
input int    KijunSenPeriod   = 26; // Kijun Sen
input int    SenkouSpanPeriod = 52; // Senkou Span

input string s3 = "----- Ichimoku Strategy -----";
input bool    IdealStrategy                  = true;    // Ideal Strategy (using Ichimoku Time Frame)
input int      maxTradeIdealStrategy         = 1;    // Max Open Trade for Ideal Strategy
input bool    TenkanKijunStrategy            = true;    // Tenkan/Kijun/Chikou Crossing Strategy (using Ichimoku Time Frame)
input int      maxTradeTenkanKijunStrategy   = 1;    // Max Open Trade for Tenkan/Kijun/Chikou Crossing Strategy

input bool    KumoBreakoutStrategy                       = true;    // Kumo Breakout Strategy
input ENUM_TIMEFRAMES    KumoBreakoutStrategyTimeFrame   = PERIOD_H1;    // Kumo Breakout Strategy Time Frame
input int      maxTradeKumoBreakoutStrategy              = 1;    // Max Open Trade for Kumo Breakout Strategy

input bool    ChikouSpanStrategy                                = true;    // Chikou Span Crossing Strategy
input ENUM_TIMEFRAMES    ChikouSpanStrategyTimeFrame            = PERIOD_M5;    // Chikou Span Strategy Time Frame
input int      maxTradeChikouSpanStrategy              = 1;    // Max Open Trade for Chikou Span Strategy


input string s4 = "----- Trailing Settings -----";
input bool EnableTrailing                          = true;  // Enable Trailing
input int   TrailingStart                          = 1;  // Minimal profit of trailing stop in points
input int   TrailingStep                           = 1;   // Stop loss movement step
input ENUM_TIMEFRAMES TrailingPeriod               = PERIOD_M1;  // Trailing Period
input MY_EA_ENUM_TRAILING_METHOD TrailingMethod    = e;  // Trailing Method
input color TrailingLabelColor                     = Lime; //Trailing Label Color
input int    TrailingDelta                         = 35;      // Offset from the stop loss calculation level
input int    ATRPeriod                             = 14; // ATR period (for ATR Trailing)
input double SARStep                               = 0.02; // Parabolic SAR Step (for Parabolic Trailing)
input double SARMaximum                            = 0.2; // Parabolic Maximum (for Parabolic Trailing)
input int MAPeriod                                 = 34; // MA period (for MA Trailing)
input ENUM_MA_METHOD MAMethod                      = MODE_SMA; // Averaging method (for MA Trailing)
input ENUM_APPLIED_PRICE MAAppliedPrice            = PRICE_CLOSE; // Price type (for MA Trailing)
//input double PercentProfit                       = 50; // Percent of profit (for Profit Trailing)
//input double TrailingStop                        = 35;  // Trailing Stop (0 disabled)




input string s5 = "----- Auto Close Management -----";
input bool   autoCloseEnabled       = false;           // Auto Close Order (if loss)
input int    autoCloseOrderMinute   = 15;             // Auto Close Order (within Minute(s))
input ENUM_TIMEFRAMES    RSITimeFrame = PERIOD_M15;    // Auto Close RSI Time Frame
input int    RSIPeriod = 14;                          // Auto Close RSI Period
input ENUM_APPLIED_PRICE RSIApplyPrice = PRICE_CLOSE; // Auto Close RSI Apply Price
input double RSIBuyCloseLevel = 65;                   // Auto Close RSI Buy Close Level
input double RSISellCloseLevel = 35;                  // Auto Close RSI Sell Close Level

input string s6 = "----- Other -----";
input bool   EnableAlert      = true;           // Enable alert when Open Buy/Sell/Modify/Close
input string AlertFileName    = "alert2.wav";   // Alert File Name
//input double minAngle         = 60;

int magicNumber = 9950;
datetime nextOrderDate;
datetime nextKumoBreakoutOrderDate;
datetime nextChikouSpanOrderDate;
int STOPLEVEL;
//int expirationMode;
bool expirationEnabled = true;

int tradeStrategy1 = 0;
int tradeStrategy2 = 0;
int tradeStrategy3 = 0;
int tradeStrategy4 = 0;

int OnInit() {
 
   STOPLEVEL = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   
   int exp_mode = (int)SymbolInfoInteger(Symbol(), SYMBOL_EXPIRATION_MODE);
   if ((exp_mode & 4) != 4) 
      expirationEnabled = false;
   Print("Exipration Mode: ", expirationEnabled);
   
   tradeStrategy1 = 0;
   tradeStrategy2 = 0;
   tradeStrategy3 = 0;
   tradeStrategy4 = 0;
   return(INIT_SUCCEEDED);
 }
 //+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(IsTesting()) 
      return;
   string PN = "MY_EA";
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
void OnTick()
{ 
   if(Bars<100)
   {
      Print("bars less than 100");
      return;
   }
   int arraySize = KijunSenPeriod + TenkanSenPeriod;
   
   int    cnt, ticket, total;
   double tenkanSen[];
   double kijunSen[];
   double senkouSpanA[];
   double senkouSpanB[];
   double chikouSpan[];
   double rsi;
   double maOpen[];
   double maClose[];
   int marketCondition[];
   //double angleDegree;
   
   double futureSenkouSpanA[];
   double futureSenkouSpanB[];
   int KumoCondition[];
   double KumoHigh[];
   double KumoLow[];
   double FutureKumoHigh   = 0;
   double FutureKumoLow    = 0;
   int FutureKumoCondition = 0;
   
   ArrayResize(tenkanSen, arraySize);
   ArrayResize(kijunSen, arraySize);
   ArrayResize(kijunSen, arraySize);
   ArrayResize(senkouSpanA, arraySize);
   ArrayResize(senkouSpanB, arraySize);
   ArrayResize(chikouSpan, arraySize);
   ArrayResize(futureSenkouSpanA, MY_EA_FUTURE_SIZE);
   ArrayResize(futureSenkouSpanB, MY_EA_FUTURE_SIZE);
   //ArrayResize(rsi, arraySize);
   ArrayResize(marketCondition, arraySize);
   
   ArrayResize(KumoCondition, MY_EA_KUMO_GROUP);
   ArrayResize(KumoHigh, MY_EA_KUMO_GROUP);
   ArrayResize(KumoLow, MY_EA_KUMO_GROUP);
   
   double KumoHighest = 0;
   double KumoLowest = 0; 
   int currentKumoIndex = -1;
   double KumoStrength = 0;
   double delta = 0;
   double lastDelta = 0;
   
   int magicNo = magicNumber;
   string currentDateStr = TimeToString(TimeCurrent(), TIME_DATE);
   string lastDateStr = TimeToString(Time[3], TIME_DATE);
   int h = TimeHour(TimeCurrent());
   int m = TimeMinute(TimeCurrent());
   int availMinute = -1;
   datetime nowTime = (h * 60 * 60 + m * 60);
   string currentChikouDateStr = TimeToString(Time[KijunSenPeriod], TIME_DATE);
   string Label = "";
   datetime tradeStart;
   datetime tradeEnd;
   
   if (Period() < PERIOD_D1) {
      for(int i=0;i<2;i++)
      {
         if (SymbolInfoSessionTrade(Symbol(), DayOfWeek(), i, tradeStart, tradeEnd)) {
            
            if (tradeStart <= nowTime && nowTime <= tradeEnd) {
               availMinute = (tradeEnd - nowTime) / 60;
               break;
            } 
         }
      }
   }
   for(int i = 0; i < arraySize; i++)
   {
      tenkanSen[i] = iIchimoku(Symbol(), IchimokuTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_TENKANSEN, i);
      kijunSen[i] = iIchimoku(Symbol(), IchimokuTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_KIJUNSEN, i);
      senkouSpanA[i] = iIchimoku(Symbol(), IchimokuTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_SENKOUSPANA, i);
      senkouSpanB[i] = iIchimoku(Symbol(), IchimokuTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_SENKOUSPANB, i);
      chikouSpan[i] = iIchimoku(Symbol(), IchimokuTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_CHIKOUSPAN, i);
      //rsi[i] = iRSI(Symbol(), RSITimeFrame, RSIPeriod, PRICE_CLOSE, i);
      
      if (KumoHighest == 0 || KumoHighest < senkouSpanA[i])
            KumoHighest = senkouSpanA[i];
      if (KumoHighest == 0 || KumoHighest < senkouSpanB[i])
            KumoHighest = senkouSpanB[i];
      if (KumoLowest == 0 || KumoLowest > senkouSpanA[i])
            KumoLowest = senkouSpanA[i];
      if (KumoLowest == 0 || KumoLowest > senkouSpanB[i])
            KumoLowest = senkouSpanB[i];
      
      if (currentKumoIndex < MY_EA_KUMO_GROUP - 1) {
         delta = senkouSpanA[i] - senkouSpanB[i];
         if (
               (delta > 0 && lastDelta < 0) 
               || (delta < 0 && lastDelta > 0) 
               || (lastDelta == 0)
             )
         {
            currentKumoIndex += 1;
         }
         if (delta > 0) {
            KumoCondition[currentKumoIndex] = MY_EA_BULLISH;
            if (KumoHigh[currentKumoIndex] == 0 || KumoHigh[currentKumoIndex] < senkouSpanA[i])
                  KumoHigh[currentKumoIndex] = senkouSpanA[i];
            if (KumoLow[currentKumoIndex] == 0 || KumoLow[currentKumoIndex] > senkouSpanB[i])
                  KumoLow[currentKumoIndex] = senkouSpanB[i];
         }
         else {
            KumoCondition[currentKumoIndex] = MY_EA_BEARISH;
            if (KumoHigh[currentKumoIndex] == 0 || KumoHigh[currentKumoIndex] < senkouSpanB[i])
                  KumoHigh[currentKumoIndex] = senkouSpanB[i];
            if (KumoLow[currentKumoIndex] == 0 || KumoLow[currentKumoIndex] > senkouSpanA[i])
                  KumoLow[currentKumoIndex] = senkouSpanA[i];
         }
         lastDelta = delta;
      }
      if (
         (senkouSpanB[i] > kijunSen[i])
            && (senkouSpanA[i] > kijunSen[i])
            && (kijunSen[i] > tenkanSen[i])
            && (tenkanSen[i] > Close[i])
         ) 
      {
         marketCondition[i] = MY_EA_BEARISH;
      }
      else if (
         (Close[i] > tenkanSen[i])
            && (tenkanSen[i] > kijunSen[i])
            && (kijunSen[i] > senkouSpanA[i])
            && (kijunSen[i] > senkouSpanB[i])
         )
      {    
         marketCondition[i] = MY_EA_BULLISH;
      }
      else{
         marketCondition[i] = MY_EA_CONSOLIDATE;      
      }
   }
   
   for(int i = 0; i < MY_EA_FUTURE_SIZE; i++)
   {
      futureSenkouSpanA[i] = iIchimoku(Symbol(), IchimokuTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_SENKOUSPANA, -i - 1);
      futureSenkouSpanB[i] = iIchimoku(Symbol(), IchimokuTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_SENKOUSPANB, -i - 1);
      if (FutureKumoHigh == 0 || FutureKumoHigh < futureSenkouSpanA[i])
            FutureKumoHigh = futureSenkouSpanA[i];
      if (FutureKumoHigh == 0 || FutureKumoHigh < futureSenkouSpanB[i])
            FutureKumoHigh = futureSenkouSpanB[i];
      if (FutureKumoLow == 0 || FutureKumoLow > futureSenkouSpanA[i])
            FutureKumoLow = futureSenkouSpanA[i];
      if (FutureKumoLow == 0 || FutureKumoLow > futureSenkouSpanB[i])
            FutureKumoLow = futureSenkouSpanB[i];
            
   }
   if (futureSenkouSpanA[MY_EA_FUTURE_SIZE - 1] > futureSenkouSpanB[MY_EA_FUTURE_SIZE - 1])
      FutureKumoCondition = MY_EA_BULLISH;
   else
      FutureKumoCondition = MY_EA_BEARISH;
   
   total = OrdersTotal();
   KumoStrength = MathAbs(senkouSpanA[0] - senkouSpanB[0]);
   
   if (total <= maxTrade 
         && (nextOrderDate < TimeCurrent()) //avoid duplicate order on the same time
         && (currentDateStr == lastDateStr) //avoid gap on next session/period
         ) {
      bool isValidSignal = false;
      bool IsCrossing = false;
      bool IsTenkanKijunCrossing = false;
      bool IsChikouTenkanKijunCrossing = false;
      int signal = marketCondition[0];
      int crossingIndex = 0;
      

      lastDelta = 0;
      //Check Crossing tenkanSen vs kijunSen
      for(int i=0; i < 5; i++)
      {
         delta = tenkanSen[i] - kijunSen[i];
         if (lastDelta == 0) {
            lastDelta = delta;
            continue;
         }
         if (lastDelta < 0 && delta > 0) {
            IsTenkanKijunCrossing =  true;
            crossingIndex = i;
            break;
         }
         else if (lastDelta > 0 && delta < 0) {
            IsTenkanKijunCrossing = true;
            crossingIndex = i;
            break;
         }
      }
      
//+------------------------------------------------------------------+
//| Ideal Strategy                                                   |
//+------------------------------------------------------------------+
      if (IdealStrategy && !isValidSignal && IsTenkanKijunCrossing) {
         if (signal == MY_EA_BULLISH && FutureKumoCondition == MY_EA_BULLISH) {
            if (Ask > FutureKumoHigh && Ask > KumoHighest) {
               isValidSignal = true;
            }
         }
         else if (signal == MY_EA_BEARISH && FutureKumoCondition == MY_EA_BEARISH) {
            if (Bid < FutureKumoLow && Bid < KumoLowest) {
               isValidSignal = true;
            }
         }
         else
            isValidSignal = false;
         
         if (KumoStrength < 40)
            isValidSignal = false;
         if (isValidSignal) {
            Label = "Ichimoku EA - Ideal Strategy";
            if (maxTradeIdealStrategy <= tradeStrategy1)
               isValidSignal = false;
         }
      }
      
      //// Crossing debug
      //if (TimeCurrent() >= 1562316180 && TimeCurrent() <= 1562316300) {
      //   Print("DEBUG 1 Tenkan vs Kijun ", "IsCrossing:", IsCrossing, "TenkanSen: [", tenkanSen[0], ", ", tenkanSen[1], ", ", tenkanSen[2], ", ", tenkanSen[3], ", ", tenkanSen[4], "], KijunSen: ["
      //   , kijunSen[0], ", ", kijunSen[1], ", ", kijunSen[2], ", ", kijunSen[3], ", ", kijunSen[4], "]");
      //}
      
      
//+------------------------------------------------------------------+
//| Tenkan Sen, Kijun Sen and Chikou Span Strategy                   |
//+------------------------------------------------------------------+
      if (TenkanKijunStrategy && !isValidSignal && IsTenkanKijunCrossing
            && !(Period() < PERIOD_D1 && availMinute >= 45)) {
         if (!isValidSignal && IsTenkanKijunCrossing) {
            //angleDegree = MathAbs(MathArctan((tenkanSen[0] - tenkanSen[crossingIndex]) / (2 * crossingIndex * Period())) * 57.29577951);
            //if (angleDegree > minAngle)
            //   isValidSignal = true;
            lastDelta = 0;
            //Signal: 1, Tenkan Sen:25924.0, Kijun Sen:25922.0, Senkou Span A:25908.75, Senkou Span B:25871.0
            if (Ask > tenkanSen[0]
               && tenkanSen[0] > kijunSen[0] 
               && senkouSpanB[0] > tenkanSen[0]
               && senkouSpanA[0] > tenkanSen[0])
               signal = MY_EA_BULLISH;
            else if (Bid < tenkanSen[0]
               && tenkanSen[0] < kijunSen[0]
               && senkouSpanB[0] < tenkanSen[0]
               && senkouSpanA[0] < tenkanSen[0])
               signal = MY_EA_BEARISH;
            else
               signal = MY_EA_CONSOLIDATE;
            if (signal != MY_EA_CONSOLIDATE) {
               for(int i=KijunSenPeriod; i < arraySize; i++)
               {
                  if (signal == MY_EA_BULLISH)
                     delta = chikouSpan[i] - tenkanSen[i];
                  else
                     delta = kijunSen[i] - chikouSpan[i];
                     
                  if (lastDelta == 0) {
                     lastDelta = delta;
                     if (signal == MY_EA_BULLISH && delta < 0)
                        break;
                     if (signal == MY_EA_BEARISH && delta < 0)
                        break;
                     continue;
                  }
                  if (lastDelta < 0 && delta > 0) {
                     IsChikouTenkanKijunCrossing =  true;
                     break;
                  }
                  else if (lastDelta > 0 && delta < 0) {
                     IsChikouTenkanKijunCrossing = true;
                     break;
                  }
               }  
            }
            else
               IsChikouTenkanKijunCrossing = false;
               
            if (IsChikouTenkanKijunCrossing) {
               if (Period() < PERIOD_D1 && currentChikouDateStr != currentDateStr){ 
                  isValidSignal = false;
               }
               else {
                  Label = "Ichimoku EA - Tenkan/Kijun Crossing Strategy";
                  magicNo = magicNumber + 1;
                  isValidSignal = true;
                  if (maxTradeTenkanKijunStrategy <= tradeStrategy2)
                     isValidSignal = false;
               }
               //Print("CrossingIndex: ", crossingIndex, ", TenkanSen Crossing: ", tenkanSen[crossingIndex], ", Angle: ", angleDegree, ", Signal: ", signal, ", Tenkan Sen:", tenkanSen[0], ", Kijun Sen:", kijunSen[0], ", Senkou Span A:" , senkouSpanA[0],", Senkou Span B:" , senkouSpanB[0]);
            }
         }
         //if (TimeCurrent() >= 1562316180 && TimeCurrent() <= 1562316300) {
         //   Print("DEBUG 2 Chikou Span ", "Angle:", angleDegree, ", IsCrossing:", IsCrossing, ", Crossing Index:", crossingIndex, " Signal:", signal, 
         //   ", Time: [", Time[26], ", ", Time[27], ", ", Time[28], ", ", Time[29], ", ", Time[30], "]"
         //   ", TenkanSen: [", tenkanSen[26], ", ", tenkanSen[27], ", ", tenkanSen[28], ", ", tenkanSen[29], ", ", tenkanSen[30], "]"
         //   ", KijunSen: [", kijunSen[26], ", ", kijunSen[27], ", ", kijunSen[28], ", ", kijunSen[29], ", ", kijunSen[30], "]"
         //   ", ChikouSpan: [", chikouSpan[26], ", ", chikouSpan[27], ", ", chikouSpan[28], ", ", chikouSpan[29], ", ", chikouSpan[30], "]"
         //   );
         //}
      }
      
      
//+------------------------------------------------------------------+
//| Kumo Breakout Strategy                                           |
//+------------------------------------------------------------------+
      if (KumoBreakoutStrategy && !isValidSignal && TimeCurrent() > nextKumoBreakoutOrderDate) {
         double priceCloseKumo[10];
         double kumoHigh[10];
         double kumoLow[10];
         signal = MY_EA_CONSOLIDATE;
         isValidSignal = true;
         double kumoThick = 0;
         for(int i=0;i<10;i++)
         {
            senkouSpanA[i] = iIchimoku(Symbol(), KumoBreakoutStrategyTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_SENKOUSPANA, i);
            senkouSpanB[i] = iIchimoku(Symbol(), KumoBreakoutStrategyTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_SENKOUSPANB, i);
            kumoThick = MathAbs(senkouSpanA[i] - senkouSpanB[i]);
            kumoHigh[i] = MY_EA_Max(senkouSpanA[i], senkouSpanB[i]);
            kumoLow[i] = MY_EA_Min(senkouSpanA[i], senkouSpanB[i]);
            if (i == 0) {
               priceCloseKumo[i] = Close[0];
               if (priceCloseKumo[i] > kumoHigh[i] && kumoThick > 40) {
                  signal = MY_EA_BULLISH;
                  continue;
               }
               else if (priceCloseKumo[i] < kumoLow[i] && kumoThick > 40) {
                  signal = MY_EA_BEARISH;
                  continue;
               }
               else {
                  isValidSignal = false;
                  break;
               }
            }
            else {
               priceCloseKumo[i] = iClose(Symbol(), KumoBreakoutStrategyTimeFrame, i);
            }
            
            if (i == 1) { // Signal Confirmation
               if (signal == MY_EA_BULLISH && priceCloseKumo[i] <= kumoHigh[i]) {
                  isValidSignal = false;
                  break;
               } 
               else  if (signal == MY_EA_BEARISH && priceCloseKumo[i] >= kumoLow[i]) {
                  isValidSignal = false;
                  break;
               }
            } 
            else if (signal == MY_EA_BULLISH) {
               if (priceCloseKumo[i] >= kumoHigh[i]) {
                  isValidSignal = false;
                  break;
               }
            }
            else if (signal == MY_EA_BEARISH) {
               if (priceCloseKumo[i] <= kumoLow[i]) {
                  isValidSignal = false;
                  break;
               }
            }
         }
         if (isValidSignal) {
            nextKumoBreakoutOrderDate = TimeCurrent() + (KumoBreakoutStrategyTimeFrame * 60);
            Label = "Ichimoku EA - Kumo Breakout Strategy";
            magicNo = magicNumber + 2;
            
            if (maxTradeKumoBreakoutStrategy <= tradeStrategy3)
               isValidSignal = false;
            //Print("DEBUG 3 Kumo Breakout", " Signal:", signal, 
            //   ", senkouSpanA: [", senkouSpanA[0], ", ", senkouSpanA[1], ", ", senkouSpanA[2], ", ", senkouSpanA[3], ", ", senkouSpanA[4], "]"
            //   ", senkouSpanB: [", senkouSpanB[0], ", ", senkouSpanB[1], ", ", senkouSpanB[2], ", ", senkouSpanB[3], ", ", senkouSpanB[4], "]"
            //   ", priceCloseKumo: [", priceCloseKumo[0], ", ", priceCloseKumo[1], ", ", priceCloseKumo[2], ", ", priceCloseKumo[3], ", ", priceCloseKumo[4], "]"
            //   ", kumoHigh: [", kumoHigh[0], ", ", kumoHigh[1], ", ", kumoHigh[2], ", ", kumoHigh[3], ", ", kumoHigh[4], "]"
            //);
         }
      }
      
      
//+------------------------------------------------------------------+
//| Chikou Span Crossing Strategy                                    |
//+------------------------------------------------------------------+
      if (ChikouSpanStrategy && !isValidSignal && TimeCurrent() > nextChikouSpanOrderDate) {
         double chikouPrice[10];
         double timeframePrice[10];
         isValidSignal = true;
         signal = MY_EA_CONSOLIDATE;
         double res = 0;
         double sup = 0;
         for(int i=0;i<10;i++)
         {
            chikouSpan[i] = iIchimoku(Symbol(), ChikouSpanStrategyTimeFrame, TenkanSenPeriod, KijunSenPeriod, SenkouSpanPeriod, MODE_CHIKOUSPAN, KijunSenPeriod + i);
            chikouPrice[i] = iClose(Symbol(), ChikouSpanStrategyTimeFrame, KijunSenPeriod + i);
            if (i == 0) {
               timeframePrice[i] = Close[i];
               if (chikouPrice[i] < chikouSpan[i])
                  signal = MY_EA_BULLISH;
               else if (chikouPrice[i] > chikouSpan[i])
                  signal = MY_EA_BEARISH;
               else
                  signal = MY_EA_CONSOLIDATE;
                
            }
            else {
               if (signal == MY_EA_CONSOLIDATE) {
                  isValidSignal = false;
                  break;
               }
               timeframePrice[i] = iClose(Symbol(), ChikouSpanStrategyTimeFrame, i);
            }
            if (res == 0 || res < timeframePrice[i])
               res = timeframePrice[i];
            if (sup == 0 || sup > timeframePrice[i])
               sup = timeframePrice[i];
            if (i == 0)
               continue;
            else if (i == 1) { // Signal Confirmation
               if (signal == MY_EA_BULLISH && chikouPrice[i] >= chikouSpan[i]) {
                  isValidSignal = false;
                  break;
               } 
               else  if (signal == MY_EA_BEARISH && chikouPrice[i] <= chikouSpan[i]) {
                  isValidSignal = false;
                  break;
               }
            }
            else if (signal == MY_EA_BULLISH) {
               if (chikouPrice[i] <= chikouSpan[i]) {
                  isValidSignal = false;
                  //if (i > 2) {
                  //   Print("DEBUG 4 Chikou Span Crossing", " Signal:", signal, 
                  //   ", timeframePrice: [", timeframePrice[0], ", ", timeframePrice[1], ", ", timeframePrice[2], ", ", timeframePrice[3], ", "
                  //   ", chikouPrice: [", chikouPrice[0], ", ", chikouPrice[1], ", ", chikouPrice[2], ", ", chikouPrice[3], ", "
                  //   ", chikouSpan: [", chikouSpan[0], ", ", chikouSpan[1], ", ", chikouSpan[2], ", ", chikouSpan[3]
                  //   );
                  //}
                  break;
               }
            }
            else if (signal == MY_EA_BEARISH) {
               if (chikouPrice[i] >= chikouSpan[i]) {
                  isValidSignal = false;
                  //if (i > 2) {
                  //   Print("DEBUG 4 Chikou Span Crossing", " Signal:", signal, 
                  //   ", timeframePrice: [", timeframePrice[0], ", ", timeframePrice[1], ", ", timeframePrice[2], ", ", timeframePrice[3], ", "
                  //   ", chikouPrice: [", chikouPrice[0], ", ", chikouPrice[1], ", ", chikouPrice[2], ", ", chikouPrice[3], ", "
                  //   ", chikouSpan: [", chikouSpan[0], ", ", chikouSpan[1], ", ", chikouSpan[2], ", ", chikouSpan[3]
                  //   );
                  //}
                  break;
               }
            }
            
         }
         if (isValidSignal) {
            //Print("HIT !!");
            isValidSignal = false;
            Label = "Ichimoku EA - Chikou Span Crossing Strategy";
            magicNo = magicNumber + 3;
            nextChikouSpanOrderDate = TimeCurrent() +  (ChikouSpanStrategyTimeFrame * 60);
            
           if (maxTradeChikouSpanStrategy > tradeStrategy4) {
               if (signal == MY_EA_BULLISH) { //buy stop
                  if ((Ask - sup) < STOPLEVEL || (BuyStopLoss > 0 && (Ask - sup) < BuyStopLoss))
                     sup = BuyStopLoss < STOPLEVEL ? Ask - STOPLEVEL * Point : Ask - BuyStopLoss * Point;
                  if ((res - Ask) < STOPLEVEL)
                     res = Ask + STOPLEVEL * Point;
                  if (expirationEnabled)   
                     ticket = OrderSend(Symbol(), OP_BUYSTOP, Lots, res, 3, sup, 0, Label, magicNo, (2 * ChikouSpanStrategyTimeFrame * 60), clrNONE);
                  else
                     ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, Ask - BuyStopLoss * Point, 0, Label, magicNo, 0, clrNONE);
                     
                  if (ticket > 0) {
                     Print(Label, " BUY order opened: ", OrderOpenPrice());
                     nextChikouSpanOrderDate = TimeCurrent() +  (ChikouSpanStrategyTimeFrame * 60);
                  }
                  else {
                     Print(Label, "Error BUY STOP Ask: ", Ask, " Price: ", res, " SL: ", sup);
                  }
               }
               else if (signal == MY_EA_BEARISH) { // sell limit
                  if ((res - Bid) < STOPLEVEL || (SellStopLoss > 0 && (res - Bid) < BuyStopLoss))
                     res = SellStopLoss < STOPLEVEL ? Bid + STOPLEVEL * Point : Bid + SellStopLoss * Point;
                  if ((sup - Bid) < STOPLEVEL)
                     sup = Bid - STOPLEVEL * Point;
                  if (expirationEnabled)
                     ticket = OrderSend(Symbol(), OP_SELLSTOP, Lots, sup, 3, res, 0, Label, magicNo, (2 * ChikouSpanStrategyTimeFrame * 60), clrNONE);
                  else   
                     ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, Bid + SellStopLoss * Point, 0, Label, magicNo, 0, clrNONE);
                  if (ticket > 0) {
                     Print(Label, " SELL STOP order opened: ", OrderOpenPrice());
                  }
                  else {
                     Print(Label, "Error SELL LIMIT Ask: ", Bid, " Price: ", sup, " SL: ", res);
                  }
               }
           }
         }
      }
//+------------------------------------------------------------------+
//| Buy / Sell                                                       |
//+------------------------------------------------------------------+
      if (isValidSignal) {
         if (signal == MY_EA_BEARISH) {
            if (SellStopLoss > 0 && SellTakeProfit > 0) {
               ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, Bid + SellStopLoss * Point, Bid - SellTakeProfit * Point, Label, magicNo, 0, clrNONE);
            }
            else if (SellStopLoss > 0) {
               ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, Bid + SellStopLoss * Point, 0, Label, magicNo, 0, clrNONE);            
            }
            else if (SellTakeProfit > 0) {
               ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, 0, Bid - SellTakeProfit * Point, Label, magicNo, 0, clrNONE);
            }
            else {
               ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, 0, 0, Label, magicNo, 0, clrNONE);
            }
            if(ticket>0) {
               if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                  //Print("SELL order opened: ", OrderOpenPrice(), ", KumoHighest: ", KumoHighest, ", KumoLowest:", KumoLowest, ", FutureKumo:", FutureKumoCondition);
                  Print(Label, " SELL order opened: ", OrderOpenPrice());
                  nextOrderDate =   TimeCurrent() + (Period() * 60 * 3);
               }
            }
            else {
               Print("Error opening BUY order : ",GetLastError());
            }
         }
         else if (signal == MY_EA_BULLISH) {
            
            if (BuyStopLoss > 0 && BuyTakeProfit > 0) {
               ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, Ask - BuyStopLoss * Point, Ask + BuyTakeProfit * Point, "Ichimoku EA", magicNo, 0, clrNONE);
            }
            else if (BuyStopLoss > 0) {
               ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, Ask - BuyStopLoss * Point, 0, Label, magicNo, 0, clrNONE);         
            }
            else if (BuyTakeProfit > 0) {
               ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, 0, Ask + BuyTakeProfit * Point, Label, magicNo, 0, clrNONE);
            }
            else {
               ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, 0, 0, Label, magicNo, 0, clrNONE);
            }
            
            if(ticket>0){
               if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
                  //Print("BUY order opened: ", OrderOpenPrice(), ", KumoHighest: ", KumoHighest, ", KumoLowest:", KumoLowest, ", FutureKumo:", FutureKumoCondition);
                  Print(Label, " BUY order opened: ", OrderOpenPrice());
                  nextOrderDate =   TimeCurrent() + (Period() * 60 * 3);
               }
            }
            else {
               Print("Error opening BUY order : ", GetLastError());
            }
         }
      }
   }
   

//+------------------------------------------------------------------+
//| Trailing / Close                                                 |
//+------------------------------------------------------------------+
   if (total > 0)
   {
      double SL   = 0; // Stop Loss
      double OSL  = 0; //Order Stop Loss
      double OOP  = 0; // Order Open Price
      datetime OT = 0; // Order Time
      double OP = 0; // Order Profit/Loss
      
      tradeStrategy1 = 0;
      tradeStrategy2 = 0;
      tradeStrategy3 = 0;
      tradeStrategy4 = 0;
      for(cnt=0; cnt < total; cnt++)
      {
         if(!OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
            continue;
         int currentMn = OrderMagicNumber();
         if (currentMn < magicNumber && currentMn > magicNumber + 3)   
            continue;   
         if (currentMn == magicNumber)
             tradeStrategy1++;
         else if (currentMn == magicNumber + 1)
             tradeStrategy2++;
         else if (currentMn == magicNumber + 2)
             tradeStrategy3++;
         else if (currentMn == magicNumber + 3)
             tradeStrategy4++;
         if(OrderType() <= OP_SELL &&   // check for opened position 
            OrderSymbol() == Symbol())  // check for symbol
         {
               OSL  = OrderStopLoss();
               OOP = OrderOpenPrice();
               OT = OrderOpenTime();
               OP = OrderProfit();
               rsi = iRSI(Symbol(), RSITimeFrame, RSIPeriod, RSIApplyPrice, 0);
               
               //--- BUY
               if(OrderType()==OP_BUY)
               {
                  if ( autoCloseEnabled
                        && (MathAbs(OOP - OSL) == BuyStopLoss * Point())
                        && OP < 0
                        && ((TimeCurrent() - OT) / 60 > autoCloseOrderMinute)
                        && rsi >= RSIBuyCloseLevel) {
                        
                     Print("Ichimoku Order Close, ticket:", OrderTicket());
                     //--- close order and exit
                     if(!OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet))
                        Print("OrderClose error ",GetLastError());
                     continue;
                  
                  }
                  //--- should it be closed?
                  if (Bid < kijunSen[0] && OrderOpenTime() < TimeCurrent() && currentMn == magicNumber) 
                  {
                     Print("Ichimoku Order Close, ticket:", OrderTicket());
                     //--- close order and exit
                     if(!OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet))
                        Print("OrderClose error ",GetLastError());
                     continue;
                  }
                  if(EnableTrailing)
                  {
                     SL = MY_EA_SL_BAR(OP_BUY, Bid, OOP);
                     if(SL < OOP + TrailingStart * Point) 
                        continue;
                        
                     if(SL >= OSL + TrailingStep * Point && (Bid - SL) / Point > STOPLEVEL) {
                        if (!OrderModify(OrderTicket(), OOP, SL, OrderTakeProfit(), 0, Green))
                           Print("OrderModify error ",GetLastError());
                        continue;
                     }
                     //if(Bid-OrderOpenPrice()>Point*TrailingDelta)
                     //{
                     //   if(OrderStopLoss()<Bid-Point*TrailingDelta)
                     //   {
                     //      //--- modify order and exit
                     //      if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingDelta,OrderTakeProfit(), 0, Green))
                     //         Print("OrderModify error ",GetLastError());
                     //      continue;
                     //   }
                     //}
                  }
               } 
               else {
               // SELL
                  //--- should it be closed?
                  
               
               //Print("OOP:", OOP, " OSL:", OSL, " OP:", OP, " OT:", (long)OT, " TimeCurrent:", (long)TimeCurrent(), " autoCloseOrderMinute:", autoCloseOrderMinute, " SellStopLoss:", SellStopLoss);   
               if ( autoCloseEnabled
                     && (MathAbs(OOP - OSL) == SellStopLoss * Point())
                     && OP < 0
                     && ((TimeCurrent() - OT) / 60 > autoCloseOrderMinute)
                     && rsi >= RSISellCloseLevel) {
                  Print("Ichimoku Order Close, ticket:", OrderTicket());
                  //--- close order and exit
                  if(!OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet))
                     Print("OrderClose error ",GetLastError());
                  continue;
               }
               if (kijunSen[0] < Ask && OrderOpenTime() < TimeCurrent() && currentMn == magicNumber)
               {
                  Print("Ichimoku Order Close, ticket:", OrderTicket());
                  //--- close order and exit
                  if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet))
                     Print("OrderClose error ",GetLastError());
                  continue;
               }
                
                  //--- check for trailing stop
               if(EnableTrailing)
               {
                  SL = MY_EA_SL_BAR(OP_SELL, Ask, OOP);
                  //Print("OOP :", OOP, ", OSL: ", OSL, ", SL :", SL, ", Point: ", Point, ", Ask: ", Ask, ", STOPLEVEL: ", STOPLEVEL);
                  
                  if(SL > OOP - TrailingStart * Point) 
                     continue;
                  if((SL <= OSL - TrailingStep * Point || OSL == 0) && (SL - Ask) / Point > STOPLEVEL) {
                     if (!OrderModify(OrderTicket(), OOP, SL, OrderTakeProfit(), 0, Green))
                        Print("OrderModify error ",GetLastError());
                     continue;
                  }
                  //if((OrderOpenPrice()-Ask)>(Point*TrailingDelta))
                  //{
                  //   if((OrderStopLoss()>(Ask+Point*TrailingDelta)) || (OrderStopLoss()==0))
                  //   {
                  //      //--- modify order and exit
                  //      if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingDelta,OrderTakeProfit(),0,Red))
                  //         Print("OrderModify error ",GetLastError());
                  //      continue;
                  //   }
                  //}
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MY_EA_Max(double val1, double val2) {
   if (val1 > val2)
      return val1;
   else if (val2 > val1)
      return val2;
   else
      return 0;      
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MY_EA_Min(double val1, double val2) {
   if (val1 > val2)
      return val2;
   else if (val2 > val1)
      return val1;
   else
      return 0;      
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MY_EA_ARROW(string Name, double Price, int ARROWCODE, color c) {
   ObjectDelete(Name);
   ObjectCreate(Name, OBJ_ARROW, 0, Time[0], Price, 0, 0, 0, 0);
   ObjectSetInteger(0, Name, OBJPROP_ARROWCODE, ARROWCODE);
   ObjectSetInteger(0, Name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, Name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, Name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, Name, OBJPROP_WIDTH, 1);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MY_EA_DrawLABEL(int c, string name, string Name, int X, int Y, color clr) {
   if(ObjectFind(name) == -1) {
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, c);
      ObjectSet(name, OBJPROP_XDISTANCE, X);
      ObjectSet(name, OBJPROP_YDISTANCE, Y);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   }
   ObjectSetText(name, Name, 10, "Arial", clr);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
         MY_EA_ARROW("MY_EA_SL_Buy", prc, 4, clrAqua);
         MY_EA_DrawLABEL(1, "MY_EA SL Buy", StringConcatenate("SL Buy candle ", DoubleToStr(prc, Digits)), 5, 100, TrailingLabelColor);
      }
      if(tip == OP_SELL) {
         for(i = 1; i < 500; i++) {
            prc = NormalizeDouble(iHigh(Symbol(), TrailingPeriod, i) + TrailingDelta * Point, Digits);
            if(prc != 0) if(price + STOPLEVEL * Point < prc) break;
               else prc = 0;
         }
         MY_EA_ARROW("MY_EA_SL_Sell", prc, 4, clrRed);
         MY_EA_DrawLABEL(1, "MY_EA SL Sell", StringConcatenate("SL Sell candle ", DoubleToStr(prc, Digits)), 5, 120, TrailingLabelColor);
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
         MY_EA_ARROW("MY_EA_SL_Buy", prc, 218, clrAqua);
         MY_EA_DrawLABEL(1, "MY_EA SL Buy", StringConcatenate("SL Buy Fractals ", DoubleToStr(prc, Digits)), 5, 100, TrailingLabelColor);
      }
      if(tip == OP_SELL) {
         for(i = 1; i < 100; i++) {
            prc = iFractals(Symbol(), TrailingPeriod, MODE_UPPER, i);
            if(prc != 0) {
               prc = NormalizeDouble(prc + TrailingDelta * Point, Digits);
               if(price + STOPLEVEL * Point < prc) break;
            } else prc = 0;
         }
         MY_EA_ARROW("MY_EA_SL_Sell", prc, 217, clrRed);
         MY_EA_DrawLABEL(1, "MY_EA SL Sell", StringConcatenate("SL Sell Fractals ", DoubleToStr(prc, Digits)), 5, 120, TrailingLabelColor);
      }
      break;
   case 3: // by ATR indicator
      if(tip == OP_BUY) {
         prc = NormalizeDouble(Bid - iATR(Symbol(), TrailingPeriod, ATRPeriod, 0) - TrailingDelta * Point, Digits);
         MY_EA_ARROW("MY_EA_SL_Buy", prc, 4, clrAqua);
         MY_EA_DrawLABEL(1, "MY_EA SL Buy", StringConcatenate("SL Buy ATR ", DoubleToStr(prc, Digits)), 5, 100, TrailingLabelColor);
      }
      if(tip == OP_SELL) {
         prc = NormalizeDouble(Ask + iATR(Symbol(), TrailingPeriod, ATRPeriod, 0) + TrailingDelta * Point, Digits);
         MY_EA_ARROW("MY_EA_SL_Sell", prc, 4, clrRed);
         MY_EA_DrawLABEL(1, "MY_EA SL Sell", StringConcatenate("SL Sell ATR ", DoubleToStr(prc, Digits)), 5, 120, TrailingLabelColor);
      }
      break;

   case 4: // by Parabolic indicator
      prc = iSAR(Symbol(), TrailingPeriod, SARStep, SARMaximum, 0);
      if(tip == OP_BUY) {
         prc = NormalizeDouble(prc - TrailingDelta * Point, Digits);
         if(price - STOPLEVEL * Point < prc) prc = 0;
         MY_EA_ARROW("MY_EA_SL_Buy", prc, 4, clrAqua);
         MY_EA_DrawLABEL(1, "MY_EA SL Buy", StringConcatenate("SL Buy Parabolic ", DoubleToStr(prc, Digits)), 5, 100, TrailingLabelColor);
      }
      if(tip == OP_SELL) {
         prc = NormalizeDouble(prc + TrailingDelta * Point, Digits);
         if(price + STOPLEVEL * Point > prc) prc = 0;
         MY_EA_ARROW("MY_EA_SL_Sell", prc, 4, clrRed);
         MY_EA_DrawLABEL(1, "MY_EA SL Sell", StringConcatenate("SL Sell Parabolic ", DoubleToStr(prc, Digits)), 5, 120, TrailingLabelColor);
      }
      break;

   case 5: // by MA indicator
      prc = iMA(Symbol(), TrailingPeriod, MAPeriod, 0, MAMethod, MAAppliedPrice, 0);
      if(tip == OP_BUY) {
         prc = NormalizeDouble(prc - TrailingDelta * Point, Digits);
         if(price - STOPLEVEL * Point < prc) prc = 0;
         MY_EA_ARROW("MY_EA_SL_Buy", prc, 4, clrAqua);
         MY_EA_DrawLABEL(1, "MY_EA SL Buy", StringConcatenate("SL Buy MA ", DoubleToStr(prc, Digits)), 5, 100, TrailingLabelColor);
      }
      if(tip == OP_SELL) {
         prc = NormalizeDouble(prc + TrailingDelta * Point, Digits);
         if(price + STOPLEVEL * Point > prc) prc = 0;
         MY_EA_ARROW("MY_EA_SL_Sell", prc, 4, clrRed);
         MY_EA_DrawLABEL(1, "MY_EA SL Sell", StringConcatenate("SL Sell MA ", DoubleToStr(prc, Digits)), 5, 120, TrailingLabelColor);
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
         MY_EA_ARROW("MY_EA_SL_Buy", prc, 4, clrAqua);
         MY_EA_DrawLABEL(1, "MY_EA SL Buy", StringConcatenate("SL Buy pips ", DoubleToStr(prc, Digits)), 5, 100, TrailingLabelColor);
      }
      if(tip == OP_SELL) {
         prc = NormalizeDouble(price + TrailingDelta * Point(), Digits);
         MY_EA_ARROW("MY_EA_SL_Sell", prc, 4, clrRed);
         MY_EA_DrawLABEL(1, "MY_EA SL Sell", StringConcatenate("SL Sell pips ", DoubleToStr(prc, Digits)), 5, 120, TrailingLabelColor);
      }
      break;
   }
   return(prc);
}