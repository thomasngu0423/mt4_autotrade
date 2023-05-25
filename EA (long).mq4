//+------------------------------------------------------------------+
//|                                               MyEMA_RSI_EA.mq4   |
//|                                                                  |
//|                                Copyright 2023, Thomas Ngu        |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Thomas Ngu"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Input parameters
extern int EMASlowPeriod = 50;
extern int EMAFastPeriod = 10;
extern int RSIPeriod = 14;
extern double RSIBuyLevel = 50;
extern double RSISellLevel = 50;
extern double LotSize = 0.01;
extern int StopLossPips = 200;
extern int TakeProfitPips = 100;
extern int MagicNumber = 1234; // Define the value of MagicNumber

// Colors for buy/sell signals
color buyColor = Blue;
color sellColor = Red;

bool tradingEnabled = true;

int OnInit()
{
   //--- EA initialization
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   //--- EA deinitialization
}

void OnTick()
{
   if (!tradingEnabled) {
      return;
   }

   // Calculate pip value for the current symbol
   double pipValue = MarketInfo(Symbol(), MODE_POINT);

   // Calculate EMAs
   double emaSlow = iMA(NULL, 0, EMASlowPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double emaFast = iMA(NULL, 0, EMAFastPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);

   // Calculate RSI
   double rsi = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE, 1);

   // Calculate Bollinger Bands
   double bbUpper = iBands(NULL, 0, 20, 2, 0, PRICE_CLOSE, MODE_UPPER, 1);
   double bbLower = iBands(NULL, 0, 20, 2, 0, PRICE_CLOSE, MODE_LOWER, 1);

   // Check for buy and sell signals
   bool buySignal = (emaSlow < emaFast) && (rsi < RSIBuyLevel) && (Ask < bbLower);
   bool sellSignal = (emaFast < emaSlow) && (rsi > RSISellLevel) && (Bid > bbUpper);

   // Check for open orders
   if (!IsThereAnOpenOrder()) {
       // Open buy order
       if (buySignal)
       {
          double buySL = NormalizeDouble(Bid - StopLossPips * pipValue, Digits);
          double buyTP = NormalizeDouble(Bid + TakeProfitPips * pipValue, Digits);
          int ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, buySL, buyTP, "Buy Order", MagicNumber, 0, buyColor);
       }

       // Open sell order
       if (sellSignal)
       {
          double sellSL = NormalizeDouble(Ask + StopLossPips * pipValue, Digits);
          double sellTP = NormalizeDouble(Ask - TakeProfitPips * pipValue, Digits);
          int ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, sellSL, sellTP, "Sell Order", MagicNumber, 0, sellColor);
       }
   }
}

bool IsThereAnOpenOrder()
{
   bool result = false;

   for (int i = 0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
            result = true;
            break;
         }
      }
   }

   return result;
}

