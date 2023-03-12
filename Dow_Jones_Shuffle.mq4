//+------------------------------------------------------------------+
//|                                                 tony_shuffle.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
extern double sl_pips=20;
extern double tp_pips=60;
double percent = 2.5;
extern double lot_size = 0.5;
extern double move_to_break_even_after_x_pips=10;
extern double trail_kick_in_at_pips=2;
extern double trail_behind_pips=3;
double pip_value;
int ticket;
double nyValues[2];
double nyLow = 0;
double nyHigh = 0;
double buySlip1 = 0;
double buySlip2 = 0;
double sellSlip1 = 0;
double sellSlip2 = 0;
double dailyLoss = 0;
double nyRange = 50;
double nyLowRange = 0;
double nySlippage = 0;
double nySlippage2 = 1;
double currentTarget = 0;
double lotsize;
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   pip_value = grab_pip_value();
   lotsize = lotsize_by_percent(percent,sl_pips);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(OnionTags(nyValues)&& (nyHigh==0)&& (nyLow==0))
   {       
      nyHigh = nyValues[0];
      nyLow = nyValues[1];
      
      Print("NY HIGH: ", nyHigh);
      Print("NY LOW: ", nyLow);
   }
   
   if((CheckTodaysOrders() < 1) && (nyHigh > 0) && (nyLow > 0))
   {
      if(Ask < nyLow)
      {
         int orderIDBuy = OrderSend(NULL,OP_BUY,lotsize,Ask,5,Ask-(sl_pips*pip_value),nyHigh);
         //nyHigh = 0;
      }
      if(Bid > nyHigh)
      {
         int orderIDSell = OrderSend(NULL,OP_SELL,lotsize,Bid,5,Bid+(sl_pips*pip_value),nyLow);
         //nyLow = 0;
      }
   }
   
   if(CheckTodaysOrders() > 0)
   {
      nyHigh = 0;
      nyLow = 0;
   }
   //check_trailing_stop();
   
  }
//+------------------------------------------------------------------+
bool OnionTags(double& NYValues[])
{
    //Initialize variables
    int WindowSizeInBars=4;        //number of candles to scan
    datetime time=TimeLocal();
    RefreshRates();
    double nyHighest=iHigh(Symbol(), PERIOD_H1, 0);
    double nyLowest=iLow(Symbol(), PERIOD_H1, 0);
    string HoursAndMinutes=TimeToString(time,TIME_MINUTES);
    bool running = True;

      //Scan the 12 candles and update values of highest and lowest
      if(StringSubstr(HoursAndMinutes,0,5)=="00:00")
      {
        for(int i=0; i<=WindowSizeInBars; i++)
       {
            if(iHigh(Symbol(), PERIOD_H1, i)>nyHighest) nyHighest=iHigh(Symbol(), PERIOD_H1, i);
            if(iLow(Symbol(), PERIOD_H1, i)<nyLowest) nyLowest=iLow(Symbol(), PERIOD_H1, i);
       }
         NYValues[0] = nyHighest;
         NYValues[1] = nyLowest;
         return True;
         //return values;
      }
      return False;
}
//+------------------------------------------------------------------+
double calculate_lotsize_by_currency_amount(double risk_amount, double sl_pip_distance,string symbol="")
  {
   if(symbol=="")
      symbol=Symbol();
//  printf("kkkkkkkkkkkkkkkkkkkkkk"+symbol);
   double t_size = MarketInfo(symbol,MODE_TICKVALUE);
   return ((risk_amount/sl_pip_distance)/t_size)/10;
  }
//+------------------------------------------------------------------+  
double lotsize_by_percent(double percent_to_risk,double sl_pip_distance,string symbol="")
  {
   double account_percent = AccountEquity()/100;
   double amount_we_are_risking = account_percent * percent_to_risk;
   return calculate_lotsize_by_currency_amount(amount_we_are_risking,sl_pip_distance,symbol);
  }
//+------------------------------------------------------------------+    
double grab_pip_value()
  {
   double digits = MarketInfo(Symbol(),MODE_DIGITS);
   if(digits==2 || digits==3)
     {
      return 0.01;
     }
   else
      if(digits==4 || digits==5)
        {
         return 0.0001;
        }
   return 0.0001;
  }
//+------------------------------------------------------------------+      
void check_trailing_stop()
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      double gap;
      double pnl_pips;
      OrderSelect(i,SELECT_BY_POS);
      if(OrderType()==OP_BUY)
        {
         pnl_pips = (OrderClosePrice()-OrderOpenPrice())/pip_value;
         if(pnl_pips>=trail_kick_in_at_pips)
           {
            gap = (Bid-OrderStopLoss())/pip_value;
            if(gap>trail_behind_pips)
              {
               OrderModify(OrderTicket(),Bid,Bid-(trail_behind_pips*pip_value),OrderTakeProfit(),NULL);
              }
           }
        }
      if(OrderType()==OP_SELL)
        {
         pnl_pips = (OrderOpenPrice()-OrderClosePrice())/pip_value;
         if(pnl_pips>=trail_kick_in_at_pips)
           {
            gap = (OrderStopLoss()-Ask)/pip_value;
            if(gap>trail_behind_pips)
              {
               OrderModify(OrderTicket(),Ask,Ask+(trail_behind_pips*pip_value),OrderTakeProfit(),NULL);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+        
int CheckTodaysOrders()
{
   int TodaysOrders= 0;
   for(int i = OrdersTotal()-1; i >=0; i--)
   {
      OrderSelect(i, SELECT_BY_POS,MODE_TRADES);   
      if(TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent())&& (OrderSymbol() == "GBPAUD"))
      {
         TodaysOrders += 1;
      }
   }
   return(TodaysOrders);
}
