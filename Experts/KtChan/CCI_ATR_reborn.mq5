//+------------------------------------------------------------------+
//|                                               CCI_ATR_reborn.mq5 |
//|                                                           KtChan |
//|上一个版本语法太丑陋了。重新修改。 |
//+------------------------------------------------------------------+
#property copyright "KtChan"
#property link      "https://www.mql5.com"
#property version   "1.00"

//2023.11.20 D_CCI_EA.mq5语法太难看了。重构。
//不用guapit的库
//用int来替代bool。因为int存取比较方便0=true, 1=false
//存Param所有参数都保存
//发现还是用true false比较好 2023-12-04
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
  string s_symbol;
  int b_buy;
  int b_sell;
  int b_trigger;
  double f_lots;
  string s_comment;
  long l_magic;
  string s_savefile; 
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

//设置指标Handle
int D_CCIHandle;
int ATRHandle;
double FastCCI[]; // 快速趋势线数组
double SlowCCI[]; // 慢速趋势线数组
double iATRBuffer[]; //ATR数组

int OnInit()
  {
     if (valid_indicator() != 0) return(INIT_FAILED); 
     return(INIT_SUCCEEDED);
     CopyBuffer(D_CCIHandle,0,0,24,FastCCI);
     ArraySetAsSeries(FastCCI,true);
     s_maxmin curr_maxmin;
     GetMaxMinValue(FastCCI, curr_maxmin);   

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

   
  }


int valid_indicator()
{
   D_CCIHandle = iCustom(_Symbol,PERIOD_CURRENT,"KtChan/D_CCI",init_fast_period,init_slow_period,PRICE_TYPICAL);
   if(D_CCIHandle==INVALID_HANDLE) 
   { 
      PrintFormat("Failed to create handle of the D_CCIHandle indicator for the symbol %s/%s, error code %d", 
                  "iATR", 
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

void GetMaxMinValue(const double &array[], s_maxmin &str_MM)
{

}