#property copyright "Copyright 2022, Author:KtChan."
#property version   "1.00"
#property description "Grid Martingale Strategy"

#include <KtChan/Trade.mqh>


enum OrderType{
  BuyType, // Buy方向
  SellType // Sell方向
};


// 设置EA参数
input string init_symbol = "EURUSD"; // 设置交易品种
input OrderType init_type = BuyType; // 设置开仓方向
input double init_lots = 0.01; // 设置初始下单手数
input int init_step = 200; // 设置网格间距
input int init_total = 5; // 设置单边加仓总次数
input int init_dev = 0; // 设置滑点值
input string init_title = "KtChan EA"; // 设置注释标题
input int init_magic = 15291406; // 设置EA识别码

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



enum CrossType{
  CrossUp, // Buy方向 0
  CrossDown, // Sell方向 1
  CrossDraw
};

//设置指标Handle
int D_CCIHandle;
int ATRHandle;
double FastCCI[]; // 快速趋势线数组
double SlowCCI[]; // 慢速趋势线数组
double iATRBuffer[]; //ATR数组

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
    // printf("EA循环执行一次");
    // 1.检查当前交易环境是否允许交易
    is_trade = isTrade();
    if(is_trade == false) return;
    // 获取当前指定品种信息
    getSymbolInfo(init_symbol,ea_symbol_info);
    
    double d_RealPrice=0.0;
    
    
    /*
    //此段开始增加CCI判定。
    int i = getPositionCount(init_symbol,12, init_magic);
    
    
    if (i == 0) //如果当前订单为0，直接开始判断。
    {
      is_buy=false;
      is_sell=false;
    }
    
    
    if(i == 0 )
    {
    int m = is_crossupdown();
    switch(m) //0 up, 1 down, 2 draw
      {
        case 0:
          is_buy=false;
          is_sell=true;
          break;
        case 1:
          is_buy=true;
          is_sell = false;
          break;
        case 2:
          is_buy=false;
          is_sell=false;
          break;
      }
    }
    //2024.1.15
    //同样的参数，不加判定居然比加判断效率高。
    //暂时不考虑加判定了。
    //此段结束增加CCI判定。
    */
    
    /*2024.1.16 直接用CCI 200来削峰*/
    int i = getPositionCount(init_symbol,12, init_magic);
    
    
    if (i == 0) //如果当前订单为0，直接开始判断。
    {
      renew_status();
    }


    
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
            BuyAdd(init_symbol, init_lots, 0, init_step,init_dev,ea_comment,init_magic);
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
             buy_sl_level = ea_pos_info.price - init_step * ea_symbol_info.point;
             // price : 1000 > tp: 1050
             // buy_sl_level: 950 > ask: 940
             if(buy_sl_level >= ea_symbol_info.ask)
             { 
                // 加仓操作
                ea_comment = buy_before + (string)buy_count;
                double add_lots = ea_pos_info.volume * 2.0;
                BuyAdd(init_symbol, add_lots, 0, init_step, init_dev, ea_comment,init_magic);
                
                // 将 buy方向所有订单的止盈修改为最新订单的止盈
                // 获取最后订单的序号
                int next_index = getIndexByTicket(init_symbol, 0, ea_comment, init_magic);
                // 获取最后订单信息
                getPositionInfo(next_index,ea_pos_info);
                d_RealPrice = GetRealPrice(0,init_magic,"");
                //UpdatePosition(init_symbol, 0,ea_pos_info.price, 0, init_step, init_magic);
                UpdatePosition(init_symbol, 0,d_RealPrice, 0, init_step, init_magic);
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
            SellAdd(init_symbol, init_lots, 0, init_step,init_dev,ea_comment,init_magic);
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
             sell_sl_level = ea_pos_info.price + init_step * ea_symbol_info.point;
             // price : 1000 > tp: 950
             // sell_sl_level: 1050 < ask: 1060
             if(sell_sl_level <= ea_symbol_info.ask)
             { 
                // 加仓操作
                ea_comment = sell_before + (string)sell_count;
                double add_lots = ea_pos_info.volume * 2.0;
                SellAdd(init_symbol, add_lots, 0, init_step, init_dev, ea_comment,init_magic);
                
                // 将 buy方向所有订单的止盈修改为最新订单的止盈
                // 获取最后订单的序号
                int next_index = getIndexByTicket(init_symbol, 1, ea_comment, init_magic);
                // 获取最后订单信息
                getPositionInfo(next_index,ea_pos_info);
                d_RealPrice = GetRealPrice(1,init_magic,"");
                //UpdatePosition(init_symbol, 1,ea_pos_info.price, 0, init_step, init_magic);
                UpdatePosition(init_symbol, 1,d_RealPrice, 0, init_step, init_magic);
                // 获取sell最后订单的止盈价
                sell_tp_level = ea_pos_info.tp;
             }
             
          }
       }
    }


   
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


int valid_indicator()
{
   D_CCIHandle = iCustom(_Symbol,PERIOD_CURRENT,"KtChan/D_CCI",18,54,PRICE_TYPICAL);
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

void renew_status()
{
  CopyBuffer(D_CCIHandle,0,0,10,FastCCI); 
  ArraySetAsSeries(FastCCI,true);
  if(FastCCI[0] < -200.00) //当快线低于-200时，多头信号打开
  {
    is_buy = true;
    is_sell = false;
  }
  else if(FastCCI[0] > 200.00) //当快线高于200时，空头信号打开
  {
    is_buy = false;
    is_sell = true;
  }
  else
  {
    is_buy = false;
    is_sell = false;  
  }
        
}
