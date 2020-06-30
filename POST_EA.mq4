//+------------------------------------------------------------------+
//|                                                      POST_EA.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//INPUT tradeURL HERE. PLEASE WATCH tradeURL IN YOUR LOGIN PAGE.
//+------------------------------------------------------------------+
string tradeURL = "https://fxcopytrade.herokuapp.com/history/1";
//+------------------------------------------------------------------+


string TradingData()
{
   //this function returns ticket_number, Symbol, and Type. From all trade pool.
   string PreTradingData = AccountInfoInteger(ACCOUNT_LOGIN)+"@";
   datetime current = TimeCurrent();
   for(int i=0;i<OrdersTotal();i++)
   {  
      bool selected_trade = OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(selected_trade == true) 
      { 
         datetime ordertime = OrderOpenTime();
         int diff_second  = current - ordertime;
         
         if(diff_second < 1){
            Print("Open Order accept");
             ulong ticket_number = OrderTicket();
             string symbol =OrderSymbol();
             int type = OrderType();
             PreTradingData += ticket_number+","+symbol+","+type+","+ OrderLots()+","+ordertime+"@";
         }
         
      } 
   }
   return(PreTradingData);
}

string Closeddata()
{ //return ticketnumber and time
   string PreTradingData = AccountInfoInteger(ACCOUNT_LOGIN)+"@";
   datetime current = TimeCurrent();
   for(int i=0;i<OrdersHistoryTotal();i++)
   {  
     bool selected_trade = OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);
     if(selected_trade == true) 
     {  
        datetime ordertime = OrderCloseTime();
        int diff_second  = current - ordertime;
        if(diff_second < 1){
            ulong ticket_number = OrderTicket();
            PreTradingData += ticket_number +","+OrderCloseTime()+","+ diff_second + "@";
        }
     }
   }
   return(PreTradingData);
}

string PastCloseddada()
{
  string PreTradingData = AccountInfoInteger(ACCOUNT_LOGIN)+"@";
  for(int i=0;i<OrdersHistoryTotal();i++)
  {  
     bool selected_trade = OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);
     datetime current = TimeCurrent();
     if(selected_trade == true) 
     {  
       datetime ordertime = OrderCloseTime();
       int diff_second  = current - ordertime; 
       ulong ticket_number = OrderTicket();
       PreTradingData += ticket_number +","+OrderCloseTime()+","+ diff_second + "@";
     }
  }
  return(PreTradingData);        
}




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   EventSetTimer(1);
  
   //Data has server password,using company, account name, 
   //  account id,mail adress, demo info, and receiver password
    string Data = "postpasskey="+"password"
                +"&type="+"type"
                +"&accountcompany="+AccountInfoString(ACCOUNT_COMPANY)
                +"&accountname="+AccountInfoString(ACCOUNT_NAME)
                +"&accountnumber="+AccountInfoInteger(ACCOUNT_LOGIN)
                +"&email="+"YourEmailAddress"
                +"&isdemo="+IntegerToString(IsDemo())
                +"&enduserpassword="+"EnduserPassword"
                +"&dummy=none";
                
     string URL = "https://fxcopytrade.herokuapp.com/active";
     SendPOST(URL,Data);          
                
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
    EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    closeddata = "&closeddata=" + PastCloseddada();
    SendPOST(tradeURL,closeddata);
   
  }
//+------------------------------------------------------------------+

//
int WebR; 
int timeout = 5000;
string cookie = NULL;
string headers; 
 

void SendPOST(string URL, string str)
{
   
   char post[],ReceivedData[];
   StringToCharArray( str, post );
   WebR = WebRequest( "POST", URL, cookie, NULL, timeout, post, 0, ReceivedData, headers );
   if(!WebR) Print("Web request failed");   
   
}

string tradingdata;
string closeddata;

void OnTimer(){
  
  //Length of TradingData will be longer than 10 when order is happen within 1 second. see TradingData().
  if(StringLen(TradingData()) > 10){
     tradingdata = "&tradingdata=" + TradingData();
     SendPOST(tradeURL,tradingdata);
  }
  if(StringLen(Closeddata()) > 10){
     closeddata = "&closeddata=" + Closeddata();
     SendPOST(tradeURL,closeddata);
  }
  
  
}