//+------------------------------------------------------------------+
//|                                                      EA_stnd.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"


string getUninitReasonText(int reasonCode) 
  { 
   string text=""; 
   switch(reasonCode) 
     { 
      case REASON_ACCOUNT: 
         text="帐号发生改变";break; 
      case REASON_CHARTCHANGE: 
         text="交易品种 或者 时间周期发生改变";break; 
      case REASON_CHARTCLOSE: 
         text="交易品种图表发生改变";break; 
      case REASON_PARAMETERS: 
         text="输入参数发生改变";break; 
      case REASON_RECOMPILE: 
         text="脚本程序: "+__FILE__+" 已经重新编译";break; 
      case REASON_REMOVE: 
         text="脚本程序 "+__FILE__+" 已经从图表中卸载";break; 
      case REASON_TEMPLATE: 
         text="新的模板已经加载到图表上";break; 
      default:text="其他未知原因."; 
     } 

   return text; 
  }


bool isTrade()
{
  bool m_trade = false;
  if(IsStopped() == false &&
    TerminalInfoInteger(TERMINAL_CONNECTED) == true &&
    TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == true
  )
  {
      m_trade = true;
  }
  
  return m_trade;
}

int iValuetoPoint(const double f_value) //价格变成点数
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pointValue = MathAbs(f_value)/point;
   int rt_point = MathCeil(MathAbs(pointValue));
   return rt_point;
}


int Highest(const double &array[],const int depth,const int start)
  {
   if(start<0)
      return(0);

   double max=array[start];
   int    index=start;
//--- start searching
   for(int i=start-1; i>start-depth && i>=0; i--)
     {
      if(array[i]>max)
        {
         index=i;
         max=array[i];
        }
     }
//--- return index of the highest bar
   return(index);
  }
//+------------------------------------------------------------------+
//|  Search for the index of the lowest bar                          |
//+------------------------------------------------------------------+
int Lowest(const double &array[],const int depth,const int start)
  {
   if(start<0)
      return(0);

   double min=array[start];
   int    index=start;
//--- start searching
   for(int i=start-1; i>start-depth && i>=0; i--)
     {
      if(array[i]<min)
        {
         index=i;
         min=array[i];
        }
     }
//--- return index of the lowest bar
   return(index);
  }
