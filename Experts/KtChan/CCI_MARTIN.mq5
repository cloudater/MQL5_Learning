//+------------------------------------------------------------------+
//|                                                   CCI_MARTIN.mq5 |
//|                                                                  |
//|逆势交易策略 36 18 54 108
// 1. CCI交叉
// 2. ATR 6倍止损止盈
// 3. 希望增加MARTIN NET进行EA                                         |
// 4. 参考阿龙老师的11.10马丁格尔策略EA
// 4.1 用ATR 108 *6 来替换网格
// 4.1.1 今天发现现在的马丁还不如CCI_DOUBLE来的赚钱。暂时这个模型先不开发了。
//+------------------------------------------------------------------+
#property copyright "KtChan"
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <KtChan/Trade.mqh>

enum OrderType{
  BuyType, // Buy方向
  SellType // Sell方向
};

// 设置EA参数
input int init_fast_period = 18; // CCI快线周期
input int init_fast_color = clrWhite; //CCI快线颜色
input int init_slow_period = 54; // CCI慢线周期
input int init_slow_color = clrYellow; //CCI慢线颜色
input string init_symbol = "EURUSD"; // 设置交易品种
input OrderType init_type = BuyType; // 设置开仓方向
input double init_lots = 0.01; // 设置初始下单手数
input int init_atr_mult = 8; // 设置ATR的倍数
input int init_total = 5; // 设置单边加仓总次数
input int init_dev = 0; // 设置滑点值
input string init_title = "瓜皮猫EA"; // 设置注释标题
input int init_magic = 8199231; // 设置EA识别码

// 全局变量配置
bool is_buy = false;
int buy_count = 0;
string buy_before;
double buy_tp_level = 0.0;
double buy_sl_level;

bool is_sell = false;
int sell_count = 0;
string sell_before;
double sell_tp_level = 0.0;
double sell_sl_level;

bool is_trade = false;
SymbolInfo ea_symbol_info;
PositionInfo ea_pos_info;
string ea_comment;

//ATR参数设置
/*
用ATR 划分动态网格。不要每次50这样加。
*/
int ATRHandle;
double iATRBuffer[]; //ATR数组
int atr_step = 0; // 设置网格间距

//设置指标CCI Handle
int D_CCIHandle;
double FastCCI[]; // 快速趋势线数组
double SlowCCI[]; // 慢速趋势线数组

// 在程序开始前执行一次
int OnInit()
  {
   // printf("EA开始前执行一次");
   // printf("交易品种: %s", init_symbol);
   //printf("软件运行是否停止: %s",string(IsStopped()));
   //printf("服务器连接状态: %s", string(TerminalInfoInteger(TERMINAL_CONNECTED)));
   //printf("是否允许交易: %d",TerminalInfoInteger(TERMINAL_TRADE_ALLOWED));
   // printf("是否允许交易: %s", (string)isTrade());
   // 根据用户选择方向进行EA初始交易
   if(init_type == BuyType)
   {
      is_buy = true;
      is_sell = false;
   }
   else if(init_type == SellType)
   {
      is_buy = false;
      is_sell = true;
   }
   // 组合订单注释前缀
   buy_before = init_title + ": " + init_symbol + " Buy ";
   sell_before = init_title + ": " + init_symbol + " Sell ";
   
   
   ATRHandle=iATR(_Symbol,PERIOD_CURRENT,108);
   if(ATRHandle==INVALID_HANDLE) 
   { 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d", 
                  "iATR", 
                  EnumToString(PERIOD_CURRENT), 
                  GetLastError()); 
      return(INIT_FAILED); 
   }    
   

   D_CCIHandle = iCustom(_Symbol,PERIOD_CURRENT,"KtChan/D_CCI",init_fast_period,init_slow_period);
   if(D_CCIHandle==INVALID_HANDLE) 
   { 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d", 
                  "iATR", 
                  EnumToString(PERIOD_CURRENT), 
                  GetLastError()); 
      return(INIT_FAILED); 
   }    
   
   
   return(INIT_SUCCEEDED);
  }

// 在程序退出前执行一次
void OnDeinit(const int reason)
  {
     //--- 获得EA卸载的原因
     Print(__FUNCTION__," EA已经卸载, 发生卸载的原因代码: ",reason); 
     //--- 获得EA重新初始化原因注解, 也可以使用常量函数: _UninitReason
     Print(__FUNCTION__," 卸载原因说明: ",getUninitReasonText(UninitializeReason()));
  }

// 价格每跳动一次就执行一次
void OnTick()
  {
    // printf("EA循环执行一次");
    // 1.检查当前交易环境是否允许交易
    is_trade = isTrade();
    if(is_trade == false) return;
    // 获取当前指定品种信息
    getSymbolInfo(init_symbol,ea_symbol_info);
    
    CopyBuffer(ATRHandle,0,0,10, iATRBuffer);
    ArraySetAsSeries(iATRBuffer,true);
    //iValuetoPoint(iATRBuffer[0]*6); //ATR当前值的6倍，划分5档网格
    atr_step = iValuetoPoint(iATRBuffer[0]*init_atr_mult)/init_total;
    
    // 2.1 做多方向的信号
    if(is_buy == true)
    {
       // 获取当前buy方向的订单总数
       buy_count = getPositionCount(init_symbol, 0, init_magic);
       
       //--- 开始反向开仓信号
       if(buy_tp_level != 0.0)
       {
          // 1050 <  1051
          if(buy_tp_level <= ea_symbol_info.ask)
          {
             if(buy_count == 0)
             {
               is_buy = false;
               is_sell = true;
               buy_tp_level = 0.0;
             }
          }
       }
       //--- 结束反向开仓信号
       
       // 控制buy加仓的总数
       if(buy_count < init_total && is_buy == true)
       {
          if(buy_count == 0)
          {
            ea_comment = buy_before + (string)buy_count;
            BuyAdd(init_symbol, init_lots, 0, atr_step*init_total, init_dev,ea_comment,init_magic);
          }
          else if(buy_count > 0)
          {
             // 获取前一个订单注释
             ea_comment = buy_before + string(buy_count - 1); // 1- 1
             // 获取前一个订单的序号
             int pre_index = getIndexByTicket(init_symbol, 0, ea_comment, init_magic);
             // 获取前一个订单的信息
             getPositionInfo(pre_index,ea_pos_info);
             // 获取前一个订单的止损线
             buy_sl_level = ea_pos_info.price - atr_step * ea_symbol_info.point;
             // price : 1000 > tp: 1050
             // buy_sl_level: 950 > ask: 940
             if(buy_sl_level >= ea_symbol_info.ask)
             { 
                // 加仓操作
                ea_comment = buy_before + (string)buy_count;
                double add_lots = ea_pos_info.volume * 2.0;
                BuyAdd(init_symbol, add_lots, 0, atr_step, init_dev, ea_comment,init_magic);
                
                // 将 buy方向所有订单的止盈修改为最新订单的止盈
                // 获取最后订单的序号
                int next_index = getIndexByTicket(init_symbol, 0, ea_comment, init_magic);
                // 获取最后订单信息
                getPositionInfo(next_index,ea_pos_info);
                UpdatePosition(init_symbol, 0,ea_pos_info.price, 0, atr_step, init_magic);
                // 获取最后订单的盈利值
                buy_tp_level = ea_pos_info.tp;
             }
             
          }
       }
    }
    // 3.1 sell方向开仓信号
    if(is_sell == true)
    {
       // 获取当前buy方向的订单总数
       sell_count = getPositionCount(init_symbol, 1, init_magic);
       
       //--- 开始反向开仓信号
       if(sell_tp_level != 0.0)
       {
          // 950 >  940
          if(sell_tp_level >= ea_symbol_info.ask)
          {
             if(sell_count == 0)
             {
               is_buy = true;
               is_sell = false;
               sell_tp_level = 0.0;
             }
          }
       }
       //--- 结束反向开仓信号 
        
       // 控制sell加仓的总数
       if(sell_count < init_total && is_sell == true)
       {
          if(sell_count == 0)
          {
            ea_comment = sell_before + (string)sell_count;
            SellAdd(init_symbol, init_lots, 0, atr_step*init_total,init_dev,ea_comment,init_magic);
          }
          else if(sell_count > 0)
          {
             // 获取前一个订单注释
             ea_comment = sell_before + string(sell_count - 1); // 1- 1
             // 获取前一个订单的序号
             int pre_index = getIndexByTicket(init_symbol, 1, ea_comment, init_magic);
             // 获取前一个订单的信息
             getPositionInfo(pre_index,ea_pos_info);
             // 获取前一个订单的止损线
             sell_sl_level = ea_pos_info.price + atr_step * ea_symbol_info.point;
             // price : 1000 > tp: 950
             // sell_sl_level: 1050 < ask: 1060
             if(sell_sl_level <= ea_symbol_info.ask)
             { 
                // 加仓操作
                ea_comment = sell_before + (string)sell_count;
                double add_lots = ea_pos_info.volume * 2.0;
                SellAdd(init_symbol, add_lots, 0, atr_step, init_dev, ea_comment,init_magic);
                
                // 将 buy方向所有订单的止盈修改为最新订单的止盈
                // 获取最后订单的序号
                int next_index = getIndexByTicket(init_symbol, 1, ea_comment, init_magic);
                // 获取最后订单信息
                getPositionInfo(next_index,ea_pos_info);
                UpdatePosition(init_symbol, 1,ea_pos_info.price, 0, atr_step, init_magic);
                // 获取sell最后订单的止盈价
                sell_tp_level = ea_pos_info.tp;
             }
             
          }
       }
    }
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

string getUninitReasonText(int reasonCode) //卸载显示原因
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
  
int iValuetoPoint(const double f_value) //价格变成点数
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pointValue = MathAbs(f_value)/point;
   int rt_point = MathCeil(MathAbs(pointValue));
   return rt_point;
}


enum OrderSignalType{
  BuySignalType, // Buy Signal
  SellSignalType // Sell Signal
};

void OrderSignal()
{

   CopyBuffer(D_CCIHandle,0,0,10,FastCCI);
   CopyBuffer(D_CCIHandle,1,0,10,SlowCCI);

   ArraySetAsSeries(FastCCI,true);
   ArraySetAsSeries(SlowCCI,true);
   
   
   
}