//+------------------------------------------------------------------+
//|                                        双MA突破模型.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com
//| https://www.youtube.com/watch?v=ul3F59zR91M&ab_channel=%E6%8C%87%E6%A8%99%E8%88%87%E7%AD%96%E7%95%A5|
//参考视频：
1. 判断MA快线和慢线的关系。
   如果快线> 慢线。做多
   如果快线小于慢线。做空
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <KtChan\Trade.mqh>
#include <KtChan\EA_stnd.mqh>

enum OrderType{
  BuyType, // Buy方向 0
  SellType // Sell方向 1
};

//参数设置
input string div1 = "--------指标设置--------"; // 分割线
input int init_fast_period = 2; // MA快线周期
input int init_fast_color = clrWhite; //MA快线颜色
input int init_slow_period = 30; // MA慢线周期
input int init_slow_color = clrYellow; //MA慢线颜色



input string div2 = "--------EA设置--------"; // 分割线
input double init_lots = 0.01; // 下单手数
input string init_comment = "Double MA breakout EA: "; // 注释前缀
input long init_magic = 15291406; // EA识别码

input OrderType init_type = BuyType; // 设置开仓方向

int OnInit()
  {

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

   
  }
