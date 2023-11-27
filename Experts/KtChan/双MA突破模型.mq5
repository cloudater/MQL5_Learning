//+------------------------------------------------------------------+
//|                                        双MA突破模型.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com
//| https://www.youtube.com/watch?v=ul3F59zR91M&ab_channel=%E6%8C%87%E6%A8%99%E8%88%87%E7%AD%96%E7%95%A5|
//参考视频：
//1. 判断MA快线和慢线的关系。
//   如果快线<慢线。做多
//   如果快线>慢线。做空
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <KtChan\OrderTrade.mqh>
#include <KtChan\functions.mqh>


enum OrderType{
  BuyType, // Buy方向 0
  SellType // Sell方向 1
};

enum Creation 
  { 
   Call_iMA,               // use iMA 
   Call_IndicatorCreate    // use IndicatorCreate 
  }; 

//参数设置
input string div1 = "--------指标设置--------"; // 分割线
input Creation             init_idx_type=Call_iMA;                // type of the function  
input int                  init_fast_period=2;                 // period of fast ma 
input int                  init_slow_period=30;                 // period of slow ma 
input int                  init_fast_color = clrWhite; //MA快线颜色
input int                  init_slow_color = clrYellow; //MA慢线颜色
input int                  ma_shift=0;                   // shift 
input ENUM_MA_METHOD       ma_method=MODE_SMA;           // type of smoothing 
input ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE;    // type of price  
input ENUM_TIMEFRAMES      period=PERIOD_CURRENT;        // timeframe
input int                  inter_frame = 60;             //刷新频率。60表示1小时刷新一次。





input string div2 = "--------EA设置--------"; // 分割线
input double init_lots = 0.01; // 下单手数
input string init_comment = "Double MA breakout EA: "; // 注释前缀
input long init_magic = 15291406; // EA识别码

input OrderType init_type = BuyType; // 设置开仓方向



double iFastMABuffer[]; 
double iSlowMABuffer[];
int    fast_handle;
int    slow_handle;

int test_interval = 0;
OrderType currType; //当前的Type。需要用来判断是否和输入iOrderType是否相等。来决定是否切换




//EA中OnTick使用的数组
int copied;
double ArrayClose[];
double ArrayOpen[];
double ArrayHigh[];
double ArrayLow[];

double iBuyStopPrice = 0.0;




int OnInit()
  {
    fast_handle = iMA(_Symbol,PERIOD_CURRENT,init_fast_period,ma_shift,ma_method,applied_price);
    slow_handle = iMA(_Symbol,PERIOD_CURRENT,init_slow_period,ma_shift,ma_method,applied_price);

    if(fast_handle==INVALID_HANDLE) 
    { 
       PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d", 
                  "iATR", 
                  EnumToString(PERIOD_CURRENT), 
                  GetLastError()); 
       return(INIT_FAILED); 
    } 

    if(slow_handle==INVALID_HANDLE) 
    { 
       PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d", 
                  "iATR", 
                  EnumToString(PERIOD_CURRENT), 
                  GetLastError()); 
       return(INIT_FAILED); 
    }

    
    currType = iOrderType(); //初始化的时候，就给一个OrderType
    
    StartTimer();
    OnTimer(); //开始的时候，先触发一下。调试用。如果需要，后面可以关闭。
    return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
     //--- 获得EA卸载的原因
     Print(__FUNCTION__," EA已经卸载, 发生卸载的原因代码: ",reason); 
     //--- 获得EA重新初始化原因注解, 也可以使用常量函数: _UninitReason
     Print(__FUNCTION__," 卸载原因说明: ",getUninitReasonText(UninitializeReason()));
     EventKillTimer();
   
  }

void OnTick()
  {

   
  }


void OnTimer()
{
  int total = 0;
  
  test_interval = test_interval +1;
  printf("时间触发 %d 次",test_interval);
  StartTimer();
  
  //程序主体。这次不用OnTick
  double order_price = 0.0;
  datetime stop_time = TimeCurrent() + 3600;
  
  copied = CopyHigh(_Symbol,PERIOD_CURRENT,0,16, ArrayHigh);
  copied = CopyLow(_Symbol,PERIOD_CURRENT,0,16, ArrayLow);
  ArraySetAsSeries(ArrayHigh,true);
  ArraySetAsSeries(ArrayLow,true);
  
  if(currType == iOrderType()) //如果之前设的currType和重新取得的iOrderTyp一样
  {
    currType = iOrderType();
  }
  else //如果不一样，则删除挂单。并且重新赋值。
  {
    //首先，先清理挂单。
    OrderDeleteAll(_Symbol,12,init_magic,false);
    
    //删除以后，重新赋值。
    currType = iOrderType();
  }
  
  if(currType == BuyType)
  {     
     order_price = BuyStopPrice(ArrayHigh);
     //OrderSendBase(_Symbol,4,order_price,init_lots,0.0,0.0,5,2,stop_time,0.0,"buy stop",init_magic,true);
     total = OrdersTotal();
     if(total == 0) //订单为0的时候，下单。
     {
       BuyStop(_Symbol,order_price,init_lots,0.0,0.0,5,2,stop_time,0.0,"buy stop",init_magic,true);
     }
     else
     {
       OrderUpdate(_Symbol,4,"buy stop",order_price,0,0,5,2,stop_time,0.0,init_magic,true);
     }
  }
  else if(currType == SellType)
  {
     order_price = SellStopPrice(ArrayLow);
     total = OrdersTotal();
     if(total == 0) //订单为0的时候，下单。
     {
       SellStop(_Symbol,order_price,init_lots,0.0,0.0,5,2,stop_time,0.0,"sell limit",init_magic,true);
     }
     else
     {
       OrderUpdate(_Symbol,5,"sell limit",order_price,0,0,5,2,stop_time,0.0,init_magic,true);
     }
  
  }
  
}

// 启动定时器的函数
void StartTimer()
{
  int curr_min  = 0;
  int diff_time = 0;
  int interval  = 0;

  curr_min = ReturnCurrMinutes(); //设置时间差，尽量保证1小时刷新一次。
  diff_time = 60-curr_min;//5：01分就是(60-1)*60=59分钟以后执行。
  interval = inter_frame*diff_time; //inter_frame就是间隔多少秒。diff_time单位是分钟
  EventSetTimer(interval);
}


//函数iOrderType，直接判断是否是Buy or Sell
OrderType iOrderType() 
{
  OrderType Type=BuyType;
  double iFast;
  double iSlow;
  
  CopyBuffer(fast_handle,0,0,10,iFastMABuffer);
  CopyBuffer(slow_handle,0,0,10,iSlowMABuffer);
  ArraySetAsSeries(iFastMABuffer,true);
  ArraySetAsSeries(iSlowMABuffer,true);
  
  iFast=iFastMABuffer[1];
  iSlow=iSlowMABuffer[1];

//   如果快线<慢线。做多
//   如果快线>慢线。做空  
  if(iFast > iSlow)
  {
    Type = SellType;
  }
  else if(iFast < iSlow)
  {
    Type = BuyType;
  }

  return Type;
}

int ReturnCurrMinutes()
{
  MqlDateTime str_curr;
  datetime currentTime = TimeLocal(); // 获取当前本地时间
  TimeToStruct(currentTime, str_curr);
  return str_curr.min;
}


double BuyStopPrice(const double &array[])
{
  double max_price=0.0;
  max_price = array[Highest(array,15,15)];
  return max_price;
}

double SellStopPrice(const double &array[])
{
  double min_price=0.0;
  min_price = array[Lowest(array,15,15)];
  return min_price;
}



//下面3个函数用来处理OrderDelete
bool OrderDelete(const string symbol,
                    const int type,
                    const string comment,
                    const long magic,
                    const bool is_async=false
)
{
   OrderInfo m_order;
   int total = OrdersTotal();
   for(int i=total - 1;i>=0;i--)
   {
      if(!getOrderInfo(i, m_order))
        continue;
      if(m_order.magic != magic)
        continue;
      if(m_order.symbol != symbol)
        continue;
      if(m_order.type != type)
        continue;
      if(m_order.comment == comment)
      {
         return OrderDeleteBase(m_order.ticket,is_async);
      }
   }
   return false;
}
bool OrderDeleteBase(const ulong ticket,
                     const bool is_async=false)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_REMOVE;
   request.order = ticket;
   
   bool is_ok = false;
   if(is_async == false)
   {
      is_ok = OrderSend(request, result);
   }
   else
   {
      is_ok = OrderSendAsync(request, result);
   }
   
   if(!is_ok)
   {
      printf("删除挂单请求失败, 错误代码: %d", GetLastError());
      ResetLastError();
      return false;
   }
   
   return is_ok;
}

void OrderDeleteAll(const string symbol,
                    const int type,
                    const long magic,
                    const bool is_async=false
)
{
   OrderInfo m_order;
   int total = OrdersTotal();
   for(int i=total - 1;i>=0;i--)
   {
      if(!getOrderInfo(i, m_order))
        continue;
      if(m_order.magic != magic)
        continue;
      if(m_order.symbol != symbol)
        continue;
      if(m_order.type == type)
      {
         OrderDeleteBase(m_order.ticket,is_async);
      }
      else if(type == 12)
      {
         OrderDeleteBase(m_order.ticket,is_async);
      }
   }

}