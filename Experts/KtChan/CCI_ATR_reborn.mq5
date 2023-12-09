//+------------------------------------------------------------------+
//|                                               CCI_ATR_reborn.mq5 |
//|                                                           KtChan |
//|上一个版本语法太丑陋了。重新修改。 |
//+------------------------------------------------------------------+
//

/* 函数列表
valid_indicator: 初始化indicators
is_crossupdown: 判断当前的状态，上穿，下穿，保持。0-1-2
iATRValue: 获取ATR的值。


*/

//2023.11.20 D_CCI_EA.mq5语法太难看了。重构。
//不用guapit的库
//用int来替代bool。因为int存取比较方便0=true, 1=false
//存Param所有参数都保存
/*
1. is_crossupdown
3. lower200
4. upper200
5. compare_tmp
变量对比

is_buy/is_sell
*/

#include <KtChan/Trade.mqh>
#include <KtChan/functions.mqh>

enum CrossType{
  CrossUp, // Buy方向 0
  CrossDown, // Sell方向 1
  CrossDraw
};

CrossType ReturnType;

struct Params
{
  string p_symbol;
  int p_buy;
  int p_sell;
  int p_trigger;
  double p_lots;
  string p_comment;
  long p_magic;
  string p_savefile;
  CrossType p_Type; //是否只做一个方向。CrossDraw表示两边都做。这个参数手动控制。
  double p_CCI_value; //储存一下CCI的值。
};

Params is_param;
string param_file_name;

struct s_maxmin
{
  double f_max;
  int    i_max;
  double f_min;
  int    i_min;
};



//参数设置
input string div1 = "--------指标设置--------"; // 分割线
input int init_fast_period = 18; // CCI快线周期
input int init_fast_color = clrWhite; //CCI快线颜色
input int init_slow_period = 54; // CCI慢线周期
input int init_slow_color = clrYellow; //CCI慢线颜色
input bool is_ATR=true; //是否打开ATR止盈止损;


input string div2 = "--------EA设置--------"; // 分割线
input double init_lots = 0.01; // 下单手数
input string init_comment = "CCI crose+ATR EA: "; // 注释前缀
input long init_magic = 15291406; // EA识别码
input string init_savefile = "is_param.csv";//参数文件的名称
input CrossType init_type = CrossDraw; //是否做单向

//设置指标Handle
int D_CCIHandle;
int ATRHandle;
double FastCCI[]; // 快速趋势线数组
double SlowCCI[]; // 慢速趋势线数组
double iATRBuffer[]; //ATR数组

//设置运行时候的全局变量
bool g_reset=false; //系统启动的时候，判断是否是需要重新设置一些初始参数。

int OnInit()
  {
     //OnInit只是设置一些参数。没有Ticket数据。所以，不能在这里做数据判断。
     
     int cnt_position = 0;
     cnt_position = PositionsTotal();
     if(cnt_position == 0) //如果发现订单号为空，就可能需要重新判断状态位。到底是否允许触发或者下一单是buy or sell
     {
       g_reset = true; 
     }
     
     if (valid_indicator() != 0) return(INIT_FAILED);


     return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
     //--- 获得EA卸载的原因
     Print(__FUNCTION__," EA已经卸载, 发生卸载的原因代码: ",reason); 
     //--- 获得EA重新初始化原因注解, 也可以使用常量函数: _UninitReason
     Print(__FUNCTION__," 卸载原因说明: ",getUninitReasonText(UninitializeReason()));
   
  }

void OnTick()
  {
    int cnt_position=0;
    string ea_comment;
    double ea_sl=0.0;
    double ea_tp=0.0;
    
    CopyBuffer(ATRHandle,0,0,10, iATRBuffer);
    ArraySetAsSeries(iATRBuffer,true);
    if(is_ATR == true)
    {
       ea_sl=iValuetoPoint(iATRBuffer[0]*6); //ATR当前值的6倍，设置止赢，止损
       ea_tp=ea_sl;
    }  
    
    if(g_reset == true)
    {
      first_status();
      g_reset = false; //重新设置以后g_reset=false。如果position=0, 重新变成true。
    }
   
   if(is_param.p_trigger == true) //开始进入交易判断部分。
   {
     
     if(is_param.p_buy==true && is_param.p_sell==false) //如果允许做多
     {
       if(is_crossupdown() == CrossUp) //上穿做多
       {
         cnt_position = getPositionCount(_Symbol, 1, init_magic); //是否有空单
         if(cnt_position > 0)
         {
           printf("当前持空仓单数: %d",cnt_position);
           PositionClose2(_Symbol, 1, 10, init_magic); //关闭空单
         }
         ea_comment = init_comment +"Order Type:"+ is_param.p_Type;

         if(BuyAdd(_Symbol,init_lots,ea_sl,ea_tp,5,ea_comment,init_magic)) //开多
         {
	        is_param.p_trigger = false;
	        is_param.p_buy = false;
	        is_param.p_sell=true;
         }
       }
	 }
     
     else if(is_param.p_buy==false && is_param.p_sell==true) //如果允许做空
     {
       if(is_crossupdown() == CrossDown) //下穿做空
       {
         cnt_position = getPositionCount(_Symbol, 0, init_magic); //是否有多单
         if(cnt_position > 0)
         {
           printf("当前持看多单数: %d",cnt_position);
           PositionClose2(_Symbol, 0, 10, init_magic); //关闭多单
         }
         ea_comment = init_comment +"Order Type:"+ is_param.p_Type;

         if(SellAdd(_Symbol,init_lots,ea_sl,ea_tp,5,ea_comment,init_magic)) //开空
         {
	        is_param.p_trigger = false;
	        is_param.p_buy = true;
	        is_param.p_sell=false;
         }
       }
     }

   }
   renew_status();
   
  }


int valid_indicator()
{
   D_CCIHandle = iCustom(_Symbol,PERIOD_CURRENT,"KtChan/D_CCI",init_fast_period,init_slow_period,PRICE_TYPICAL);
   if(D_CCIHandle==INVALID_HANDLE) 
   { 
      PrintFormat("Failed to create handle of the D_CCIHandle indicator for the symbol %s/%s, error code %d", 
                  "D_CCIHandle", 
                  EnumToString(PERIOD_CURRENT), 
                  GetLastError()); 
      return(INIT_FAILED); 
   }

   ATRHandle=iATR(_Symbol,PERIOD_CURRENT,108);
   if(ATRHandle==INVALID_HANDLE) 
   { 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d", 
                  "iATR", 
                  EnumToString(PERIOD_CURRENT), 
                  GetLastError()); 
      return(INIT_FAILED); 
   } 

   return(INIT_SUCCEEDED);
}


int is_crossupdown() //0 up, 1 down, 2 draw
{
   CopyBuffer(D_CCIHandle,0,0,10,FastCCI);
   CopyBuffer(D_CCIHandle,1,0,10,SlowCCI);

   ArraySetAsSeries(FastCCI,true);
   ArraySetAsSeries(SlowCCI,true);
   
   if (FastCCI[2]<=SlowCCI[2] && FastCCI[1] >= SlowCCI[1])
   {
      //Cross Up
      return CrossUp;
   }
   else if (FastCCI[2]>=SlowCCI[2] && FastCCI[1] <= SlowCCI[1])
   {
      //Cross Down
      return CrossDown;
   }   
   
   return CrossDraw;
}


//从array中，取得整个数组的最大最小值。
//由此，判断是否触发b_trigger
void GetMaxMinValue(const double &array[], s_maxmin &str_MM)
{
  double max_value, min_value;
  int max_idx, min_idx;
  max_value = 0.0;
  min_value = 0.0;
  max_idx = 0;
  min_idx = 0;
  max_idx = Highest(array, 23,23);
  min_idx = Lowest(array,23,23);
  max_value = array[max_idx];
  min_value = array[min_idx];
  str_MM.f_max=max_value;
  str_MM.i_max=max_idx;
  str_MM.f_min=min_value;
  str_MM.i_min=min_idx;
}

//重置状态。first_status
//1. 重新登录的时候，重置
//2. 发现当前没有订单的时候，重置。为了处理tp以后的下一步操作。
//也许重新登录不需要执行这个操作。
//命名成first status。主要设置当position=0时，FastCCI不是取最新的。
void first_status() 
{
  //取24条FastCCI。判断最大最小值。
  //这种情况是说，一开始没有没有订单的时候，需要先通过总体的布局，判断当前状态和b_trigger, b_buy, b_sell的参数。
  //方便编写，设置几个变量。
  double _max_value=0.0;
  double _min_value=0.0;
  int _max_id=0;
  int _min_id=0;
  CopyBuffer(D_CCIHandle,0,0,24,FastCCI); 
  ArraySetAsSeries(FastCCI,true);
  s_maxmin curr_maxmin;
  GetMaxMinValue(FastCCI, curr_maxmin);
  _max_value = curr_maxmin.f_max;
  _max_id    = curr_maxmin.i_max;
  _min_value = curr_maxmin.f_min;
  _min_id    = curr_maxmin.i_min;
  //ArrayPrint(FastCCI);
  //printf("max value %.5f, max id: %d, min value: %.5f, min id: %d",curr_maxmin.f_max,curr_maxmin.i_max, curr_maxmin.f_min, curr_maxmin.i_min);
  //如果max_id < min_id && max_value > 200, 则g_sell=true, g_buy=false g_trigger再判断，开始做sell单
  //如果max_id > min_id && min_value < -200,则g_sell=false, g_buy=true g_trigger再判断，开始做buy单
  //如果max_value > 200 && min_value >-200，则g_sell=true, g_buy=false g_trigger再判断，开始做sell单
  //如果max_value < 200 && min_value <-200, g_sell=false, g_buy=true g_trigger再判断，开始做buy单
  //如果max_value < 200 min_value > -200, 什么都不做。这个不确定是否需要再次reset。如果这样，程序很臃肿。
  if(_max_value >=200.00 && _min_value <= -200.00) //当两个状态同时满足，谁新听谁的
  {
    if(_max_id < _min_id)
    {
      is_param.p_sell = true;
      is_param.p_buy  = false;
      is_param.p_trigger = true; //待定
      is_param.p_CCI_value = _max_value; //
    }else if(_max_id > _min_id)
    {
      is_param.p_sell = false;
      is_param.p_buy  = true;
      is_param.p_trigger = true; //待定
      is_param.p_CCI_value = _min_value;
    }
  }
  if(_max_value >=200 && _min_value >-200) //满足做空
  {
    is_param.p_sell = true;
    is_param.p_buy  = false;
    is_param.p_trigger = true; //待定 
    is_param.p_CCI_value = _max_value;
  }
  if(_max_value < 200 && _min_value <=-200) //满足做多
  {
    is_param.p_sell = false;
    is_param.p_buy  = true;
    is_param.p_trigger = true; //待定
    is_param.p_CCI_value = _min_value;   
  }
  if(_max_value < 200 && _min_value >-200) //持平不做
  {
    //stay
    is_param.p_trigger = false; //待定
  }
  switch(is_param.p_Type)
  {
    case CrossDown: //只做空
      is_param.p_buy=false;
      is_param.p_sell=true;
    case CrossUp:  //只做多
      is_param.p_buy=true;
      is_param.p_sell=false;
  }
}

//renew_status 当有订单的时候，如果FastCCI发生了反向创越，那么，需要重新设置状态。
//只要是发现FastCCI针对200和-200，穿越了，就准备开始新的交易挑战。
void renew_status()
{
  CopyBuffer(D_CCIHandle,0,0,10,FastCCI); 
  ArraySetAsSeries(FastCCI,true);
  if(is_param.p_buy == false && (FastCCI[1] < -200.00) ) //当快线低于-200时，多头信号打开
  {
     
     is_param.p_CCI_value = FastCCI[1];
     is_param.p_buy = true;
     is_param.p_sell = false;
     is_param.p_trigger = true;
  }
  else if(is_param.p_sell == false && (FastCCI[1] > 200.00) ) //当快线高于200时，空头信号打开
  {
     is_param.p_CCI_value = FastCCI[1];
     is_param.p_buy = false;
     is_param.p_sell = true;
     is_param.p_trigger = true;
  }       
}