//+------------------------------------------------------------------+
//|                                                  Received_EA.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//HOST USER INPUT URL HERE. PLEASE SEE URL IN YOUR ACCOUNT PAGE
//+------------------------------------------------------------------+
string URL = "https://fxcopytrade.herokuapp.com/xfocyprtda_seclet_5539366264073/1";
//+------------------------------------------------------------------+
/*
//INPUT tradeURL HERE. PLEASE WATCH tradeURL IN YOUR ACCOUNT PAGE.
//+------------------------------------------------------------------+
string tradeURL = "https://fxcopytrade.herokuapp.com/history/1";
//+------------------------------------------------------------------+
*/

int timeout = 5000;
string cookie = NULL,headers; 
char post[],ReceivedData[]; 
int WebR = WebRequest( "GET", URL, cookie, NULL, timeout, post, 0, ReceivedData, headers );
string TradingData = CharArrayToString(ReceivedData);

int TargetPos(string URL, int index)
{
   //index starts from 0
   if( StringFind(TradingData,"---getting tradingdata failed---",0) != -1 )
   {
      Print(TradingData);
   }
   
   int pos[100] = {};
   string indicator = "trade:";
   pos[0] =  StringFind(TradingData,indicator,0);
   for(int i=1; i< index; i++)
   {
      pos[i] =  StringFind(TradingData,indicator,pos[i-1] + StringLen(indicator));
   }
   return(pos[index-1]);
}

string parameter(string target, int start_pos, int target_length, string TradingData)
{
    int target_pos = StringFind(TradingData,target,start_pos);
    string sentence = StringSubstr(TradingData,target_pos + StringLen(target),target_length);
    return(sentence);
}

/*
string Closeddata()
{ //return already closed order's comment, thus, parent's ticjet number
   string PreTradingData = AccountInfoInteger(ACCOUNT_LOGIN)+",";
   datetime current = TimeCurrent();
   for(int i=0;i<OrdersHistoryTotal();i++)
   {  
      bool selected_trade = OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);
      if(selected_trade == true) 
      { 
         int diff = current - OrderCloseTime();
         if(diff < 5){
             ulong ticket_comment = OrderComment();
             PreTradingData += ticket_comment +",";
         }
      } 
   }
   return(PreTradingData);
}


void SendPOST(string URL, string str)
{
  char post[],ReceivedData[];
  StringToCharArray( str, post );
  int WebR = WebRequest( "POST", URL, cookie, NULL, timeout, post, 0, ReceivedData, headers );
  if(!WebR) Print("Web request failed");   
}
*/

int OnInit()
  {
//---   
    EventSetTimer(1);
    Print(ReceivedData[0]);
    Print(TradingData);
       
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
}

void OnTimer()
 {
//---
    string TradingData = CharArrayToString(ReceivedData);
    WebR = WebRequest( "GET", URL, cookie, NULL, timeout, post, 0, ReceivedData, headers );
    TradingData = CharArrayToString(ReceivedData);
   
    int index = 1;
    
        datetime ordertime = StringToTime(parameter("ordertime:", TargetPos(URL,index), 19, TradingData));
        datetime current = TimeCurrent();
        int diff_second = current-ordertime;
       // Print("Pretime",diff_second); //it takes 3 or 4 second.
        string sent_comment = parameter("comment:", TargetPos(URL,index),10 , TradingData);
        string ticketnumber = parameter("ticketnumber:", TargetPos(URL,index), 9, TradingData);
        string TheSymbol = parameter("symbol:", TargetPos(URL,index), 8, TradingData);
        string Direction =  parameter("deal:", TargetPos(URL,index), 1, TradingData);
        double volume =  StringToDouble(parameter("lots:", TargetPos(URL,index), 4, TradingData));
        //Print(TheSymbol);
        //Print(index);
     // Print(diff_second);
      if(diff_second < 3){
          Print("Start");
          //Print(CheckHaveThisPositionNow(ticketnumber));
          if(CheckHaveThisPositionNow(ticketnumber) == false){
                if(StringFind(sent_comment,"closed",0) == -1 ){
                   int type = 0;
                   double price = 0;
                   if( StringToInteger(Direction) == 0 )
                   {
                      type  = OP_BUY;
                      price = SymbolInfoDouble(TheSymbol,SYMBOL_ASK);//Symbol no kaine
                   }
                   if( StringToInteger(Direction) == 1 )
                   {
                      type = OP_SELL;
                      price = SymbolInfoDouble(TheSymbol,SYMBOL_BID);
                   }
                   string comment = ticketnumber;
                   int R=OrderSend(TheSymbol,type,volume,price,20,0,0,comment);
                   if(R == -1){
                        Print("ErorrCode=");
                        Print(GetLastError());
                   }
                   else{
                    Print("SUCESS");
                    int diff_second = TimeCurrent()-ordertime;
                    Print(diff_second);
                   }
                }
                else if(CheckHadThisPositionPast(ticketnumber) == true){
                  Print("This position has already past");
                }
                else{
                  Print("I DO NOT HAVE THIS POSITION BUT PARENT CLOSE!!");
                }
          }
          else if(StringFind(sent_comment,"closed",0) != -1 ){
                Print("CLOSEORDER");
                  if(CheckHadThisPositionPast(ticketnumber) == false){
                      double price = 0;
                      if( StringToInteger(Direction) == 0 )
                      {
                          price = SymbolInfoDouble(TheSymbol,SYMBOL_BID);//Symbol no kaine
                      }
                      if( StringToInteger(Direction) == 1 )
                      {
                          price = SymbolInfoDouble(TheSymbol,SYMBOL_ASK);
                      } 
                      int close_ticketnumber = ClosedTicketnumber(ticketnumber);
                      bool order = OrderClose(close_ticketnumber,volume,price,3);
      
                      if(order == true){
                        Print("CLOSE SUCCESS!!");
                      }
                      else{
                        Print("ClosingErorrCode=");
                        Print(GetLastError());
                      }
                  }
                  else{
                   Print("This position has already past");
                }
          }
          else{
            Print("I HAVE THIS POSITION");
          }
      }
      
     /* string historydata = "&historydata=" + Closeddata();
      SendPOST(tradeURL,historydata);*/
    
  }
//+------------------------------------------------------------------+

//+------------------------
//when you send order, insert parent trade ticket number to the sending comment.
//So, if the order has the comment, order is not send.







bool CheckHaveThisPositionNow(string CheckComment)
{
    //Check Comment will be parent's ticket number.
   bool ThisPositionHaveNow = false;
   
   for(int j=0;j<OrdersTotal();j++)
   {
      bool selected_trade = OrderSelect(j,SELECT_BY_POS,MODE_TRADES);
      if(selected_trade == true) 
      {   
         string PositionComment= OrderComment();
         //if you have this order, comment has "CheckComment"
         //Print(StringFind(PositionComment,CheckComment,0));
         if( StringFind(PositionComment,CheckComment,0) != -1 )
         {
            ThisPositionHaveNow = true;
            //Not entry because You have already had this position,
            break;  
         }
      } 
   } 

   return(ThisPositionHaveNow);
}


bool CheckHadThisPositionPast(string TheComment)
{
   //HistorySelect(0,TimeCurrent());  this function selects all history
   bool ThisPositionHadAlready = false;
   for(int j=0;j<OrdersHistoryTotal();j++)
   {     
      bool selected_trade = OrderSelect(j,SELECT_BY_POS,MODE_HISTORY);
      if(selected_trade == true){
          string HistoryComment = OrderComment();
          
          //if you had this position already, 
          if( StringFind(HistoryComment,TheComment,0) != -1 ) 
          {
             ThisPositionHadAlready = true;
             break;
          }
      }
   }
   return( ThisPositionHadAlready );
}

int ClosedTicketnumber(string ticketnumber)
{
  for(int j=0;j<OrdersTotal();j++)
  {     
        bool selected_trade = OrderSelect(j,SELECT_BY_POS,MODE_TRADES);
        if(selected_trade == true){
            string HistoryComment = OrderComment();
        
            if( StringFind(HistoryComment,ticketnumber,0) != -1 ) 
            {
               break;
            }
        }
  }
  return(OrderTicket());
  
}

