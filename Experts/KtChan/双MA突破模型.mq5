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

#include <KtChan\Trade.mqh>
#include <KtChan\functions.mqh>
#include <KtChan\OrderTrade.mqh>

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
    
    CopyBuffer(fast_handle,0,0,10,iFastMABuffer);
    CopyBuffer(slow_handle,0,0,10,iSlowMABuffer);
    ArraySetAsSeries(iFastMABuffer,true);
    ArraySetAsSeries(iSlowMABuffer,true);
    
    ArrayPrint(iFastMABuffer);
    ArrayPrint(iSlowMABuffer);
    
    
    currType = iOrderType(); //初始化的时候，就给一个OrderType
    
    StartTimer();
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
  test_interval = test_interval +1;
  printf("时间触发 %d 次",test_interval);
  StartTimer();
  
  //程序主体。这次不用OnTick
  copied = CopyHigh(_Symbol,PERIOD_CURRENT,0,16, ArrayHigh);
  copied = CopyLow(_Symbol,PERIOD_CURRENT,0,16, ArrayLow);
  ArraySetAsSeries(ArrayHigh,true);
  ArraySetAsSeries(ArrayLow,true);
  
  if(currType == iOrderType()) //如果之前设的currType和重新取得的iOrderTyp一样
  {
    currType = iOrderType();
  }
  
  if(currType == BuyType)
  {
     datetime stop_time = TimeCurrent() + 3600;
     iBuyStopPrice = BuyStopPrice();
     OrderSendBase(symbol,4,iBuyStopPrice,0.12,0.0,0.0,5,2,stop_time,0.0,"buy stop",init_magic,true);
  }
  else if(currType == SellType)
  {
  
  }
  
}

// 启动定时器的函数
void StartTimer()
{
  int curr_min  = 0;
  int diff_time = 0;
  int interval  = 0;
  double KK;
  curr_min = ReturnCurrMinutes(KK); //设置时间差，尽量保证1小时刷新一次。
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


double BuyStopPrice(const double array)
{
  return 0.0;
}
