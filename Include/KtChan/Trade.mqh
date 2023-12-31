//+------------------------------------------------------------------+
//|  交易请求相关函数                                                |
//+------------------------------------------------------------------+

/*
BuyAdd: Buy 控仓组件
SellAdd: Sell 控仓组件
Buy: Buy 无限制开仓组件
Sell: Sell 无限制开仓组件
PositionSend: 开仓底层组件
PositionSendBase: 开仓底层请求组件
moveSLTP: 移动止损止盈组件
moveSLTPProfit: 盈利方向的修改止损止盈
UpdatePosition: 根据目标值修改止损止盈
PositionClose: 迭代平仓组件
PositionClose2: 循环平仓组件
getPositionCount: 获取指定条件的持仓单数量
selectTicket: 查询指定订单是否存在
getIndexByTicket: 根据指定条件返回持仓单的序号
SetTypeFillingBySymbol: 设置Order Filling Mode
UpdatePositionPrice：更新sl tp，用价格而不是点数
GetRealPrice: 获取等效价格，用来算后面的马丁


校验组件
valSymbol: 验证交易品种组件
valVolume: 验证交易手数组件
valStopLossPrice: 验证止损点数组件
_valStopLossPrice: 验证止损点数私有组件
valTakeProfitPrice: 验证止盈点数组件
_valTakeProfitPrice: 验证止盈点数私有组件
*/

#include <KtChan/Symbols.mqh>
#include <KtChan/PositionInfo.mqh>
#include <KtChan/EA_stnd.mqh>



// 查询指定订单是否存在
bool selectTicket(const string symbol, const int type, const string comment, const ulong magic)
{
  string m_sym = "";
  if(symbol == NULL || symbol == "") m_sym = _Symbol;
  else m_sym = symbol;
  // 获得持仓单总数
  int len = PositionsTotal();
  for(int i=0; i<len;i++)
  {
    // 根据序号返回交易订单号
    ulong pos_ticket = PositionGetTicket(i);
    // 判断持仓单号信息是否可以成功获取
    if(PositionSelectByTicket(pos_ticket))
    {
      datetime pos_dt = (datetime)PositionGetInteger(POSITION_TIME);
      string pos_sym = PositionGetString(POSITION_SYMBOL);
      string pos_com = (string)PositionGetString(POSITION_COMMENT);
      ulong pos_magic = PositionGetInteger(POSITION_MAGIC);
      int pos_type =  (int)PositionGetInteger(POSITION_TYPE);
      //printf("交易品种: %s, 注释: %s, magic: %llu, 开仓时间: %s",pos_sym,pos_com,pos_magic,(string)pos_dt);
      //printf("pos_com: %s, comment: %s",pos_com,comment);
      // if(pos_com == comment)printf("ok");
      if(pos_magic == magic && pos_com == comment && pos_type == type)
      {
        //printf("该定单已经存在,交易品种: %s, 注释: %s, magic: %llu, 开仓时间: %s",
        //  pos_sym,pos_com,pos_magic,(string)pos_dt);
        return true;
      }
      
    }
  }
  
  // 如果 magic, 注释, 方向都相等就不用在开单了
  return false;
}
// 根据指定条件返回持仓单的序号
int getIndexByTicket(const string symbol, const int type, const string comment, const long magic)
{
   int total = PositionsTotal();
   int index = -1;
   PositionInfo pos_info;
   string m_symbol = valSymbol(symbol);
   if(m_symbol == "") return -1;
   for(int i=0;i<total;i++)
   {
      if(!getPositionInfo(i,pos_info))
         continue;
      if(pos_info.magic != magic)
         continue;
      if(pos_info.symbol != symbol)
         continue;
      if(pos_info.type != type)
         continue;
      if(comment == pos_info.comment)
      {
         index = i;
         break;
      }   
   }
   
   return index;
  
  
}



// buy方向下单函数组件
bool BuyAdd( const string symbol=NULL, // 交易品种 1
          const double volume=0.01, // 定单手数 3
          const int sl=0, // 止损价 4
          const int tp=0, // 止盈价 5
          const int deviation=5, // 滑点 6
          const string comment="", // 定单注释 7
          const ulong magic=8199231 // EA识别码 8
                  
)
{
  bool is_ticket = selectTicket(symbol,0, comment,magic);
  if(!is_ticket)
    return PositionSend(symbol, 0,volume,sl,tp,deviation,comment,magic);
  else return false;
}

// buy方向下单函数组件
bool SellAdd( const string symbol=NULL, // 交易品种 1
          const double volume=0.01, // 定单手数 3
          const int sl=0, // 止损价 4
          const int tp=0, // 止盈价 5
          const int deviation=5, // 滑点 6
          const string comment="", // 定单注释 7
          const ulong magic=8199231 // EA识别码 8
                  
)
{
  bool is_ticket = selectTicket(symbol,1, comment,magic);
  if(!is_ticket)
    return PositionSend(symbol, 1,volume,sl,tp,deviation,comment,magic);
  else return false;
}

// Buy方向订单
bool Buy(const string symbol=NULL, // 交易品种 1
         const double volume=0.01, // 定单手数 3
         const int sl=0, // 止损价 4
         const int tp=0, // 止盈价 5
         const int deviation=5, // 滑点 6
         const string comment="", // 定单注释 7
         const ulong magic=8199231 // EA识别码 8
                  
)
{
  return PositionSend(symbol, 0, volume, sl, tp,deviation, comment, magic);
}

// Sell方向订单
bool Sell(const string symbol=NULL, // 交易品种 1
         const double volume=0.01, // 定单手数 3
         const int sl=0, // 止损价 4
         const int tp=0, // 止盈价 5
         const int deviation=5, // 滑点 6
         const string comment="", // 定单注释 7
         const ulong magic=8199231 // EA识别码 8
                  
)
{
  return PositionSend(symbol, 1, volume, sl, tp,deviation, comment, magic);
}



// 止损价私有组件
double _valStopLossPrice(const string symbol, const int type, const int sl)
{
  if(sl < 0) return 0.0;
  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  if(type == 0) return valStopLossPrice(symbol, 0, ask, sl);
  else if(type == 1) return valStopLossPrice(symbol, 1, bid, sl);
  return 0.0;
}

// 止盈价私有组件
double _valTakeProfitPrice(const string symbol, const int type, const int tp)
{
  if(tp < 0) return 0.0;
  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  if(type == 0) return valTakeProfitPrice(symbol, 0, ask, tp);
  else if(type == 1) return valTakeProfitPrice(symbol, 1, bid, tp);
  return 0.0;
}


// 验证单词: valdator
// 1.验证货币对名称组件
string valSymbol(const string symbol)
{ 
  // 假如交易品种输出错了,不存在
  if(!SymbolSelect(symbol,true)) return "";
  string m_sym = "";
  if(symbol == NULL || symbol == "") m_sym = _Symbol;
  else m_sym = symbol;
  return m_sym;
}

// 2 验证开单方向组件
bool valType(const int type)
{
  if(type < 0 || type > 1) return false;
  return true;
}
// 3 验证下单手数
double valVolume(const string symbol, const double volume)
{
  // 交易品种最小下单量
  double min_vol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  // 交易品种最大下单量
  double max_vol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
  // 判断用户输入下单量是否有效
  // volume: 0.001 < min_vol: 0.01
  if(volume < min_vol) return min_vol;
  // volume: 600 > max_vol: 500
  else if(volume > max_vol) return min_vol;
  // 0.11111
  return NormalizeDouble(volume, 2);
}

// 4验证止损价组件
double valStopLossPrice(const string symbol, const int type, const double price, const int sl)
{
  if(price <= 0.0 || sl <= 0) return 0.0;
  SymbolInfo sym_info;
  getSymbolInfo(symbol, sym_info);
  if(type == 0)
  {
    // 市场价最小范围
    // ask_level = 1.210 - (10 * 0.001) = 1.200;
    double ask_level = sym_info.ask - (sym_info.stops_level * sym_info.point);
    // price_level = 1.210 - (5 * 0.001) = 1.205;
    double price_level = price - (sl * sym_info.point);
    //price_level: 1.205 >= ask_level: 1.200
    if(price_level >= ask_level) return NormalizeDouble(ask_level,sym_info.digits);
    else return NormalizeDouble(price_level, sym_info.digits);
  }
  else if(type == 1)
  {
    // 市场价最小范围
    // bid_level = 1.210 + (10 * 0.001) = 1.220;
    double bid_level = sym_info.bid + (sym_info.stops_level * sym_info.point);
    // price_level = 1.210 + (5 * 0.001) = 1.215;
    double price_level = price + (sl * sym_info.point);
    //price_level: 1.215 <= bid_level: 1.220
    if(price_level <= bid_level) return NormalizeDouble(bid_level,sym_info.digits);
    else return NormalizeDouble(price_level,sym_info.digits);
  }
  return 0.0;
}

// 5 止盈价验证组件
double valTakeProfitPrice(const string symbol, const int type, const double price, const int tp)
{
  if(price <= 0.0 || tp <= 0) return 0.0;
  SymbolInfo sym_info;
  getSymbolInfo(symbol, sym_info);
  if(type == 0)
  {
    // 市场价最小范围
    // ask_level = 1.210 + (10 * 0.001) = 1.220;
    double ask_level = sym_info.ask + (sym_info.stops_level * sym_info.point);
    // price_level = 1.210 + (5 * 0.001) = 1.215;
    double price_level = price + (tp * sym_info.point);
    // price_level: 1.215 <= ask_level: 1.220
    if(price_level <= ask_level) return NormalizeDouble(ask_level, sym_info.digits);
    else return NormalizeDouble(price_level,sym_info.digits);
  }
  else if(type == 1)
  {
    // 市场价最小范围
    // ask_level = 1.210 - (10 * 0.001) = 1.200;
    double bid_level = sym_info.bid - (sym_info.stops_level * sym_info.point);
    // price_level = 1.210 - (5 * 0.001) = 1.205;
    double price_level = price - (tp * sym_info.point);
    // price_level: 1.205 >= bid_level: 1.200
    if(price_level >= bid_level) return NormalizeDouble(bid_level, sym_info.digits);
    // price_level: 1.95 < bid_level: 1.200
    else return NormalizeDouble(price_level, sym_info.digits);
  }
  return 0.0;
}

// 6 验证滑点组件
int valDeviation(const int dev)
{
  if(dev <= 0) return 0;
  return dev;
}
// 订单请求发送接口
bool PositionSend(const string symbol, // 交易品种 1
                  const int type, // 定单方向 2
                  const double volume, // 定单手数 3
                  const int sl, // 止损价 4
                  const int tp, // 止盈价 5
                  const int deviation, // 滑点 6
                  const string comment, // 定单注释 7
                  const ulong magic // EA识别码 8
                  
)
{ 
  string m_sym = valSymbol(symbol);
  if(m_sym == "") return false;
  if(!valType(type))return false;
  double m_vol = valVolume(m_sym, volume);
  double ask = SymbolInfoDouble(m_sym ,SYMBOL_ASK);
  double bid = SymbolInfoDouble(m_sym, SYMBOL_BID);
  double m_sl = _valStopLossPrice(m_sym, type, sl);
  double m_tp = _valTakeProfitPrice(m_sym, type, tp);
  int m_dev = valDeviation(deviation);
  
  return PositionSendBase(m_sym, type,m_vol, m_sl, m_tp, m_dev, comment, magic);
}
// 发送交易请求基础函数
// 频繁修改的参数往左, 反之,往右
bool PositionSendBase(const string symbol, // 交易品种 1
                  const int type, // 定单方向 2
                  const double volume, // 定单手数 3
                  const double stop_loss, // 止损价 4
                  const double take_profit, // 止盈价 5
                  const int deviation, // 滑点 6
                  const string comment, // 定单注释 7
                  const ulong magic // EA识别码 8
                  
)
{
  // 自定义功能区
  if(type < 0 || type > 1) return false;
  
  string sym = symbol; // 1
  SymbolInfo sym_info;
  getSymbolInfo(sym, sym_info);

  // 3 创建和初始化交易请求体和返回响应结构体
  MqlTradeRequest request = {};
  MqlTradeResult result = {};

  // 4.1 请求设置相关的属性
  request.action = TRADE_ACTION_DEAL;
  if(type == 0) request.type = ORDER_TYPE_BUY; // 2
  else if(type == 1) request.type = ORDER_TYPE_SELL;
  request.type_filling = (ENUM_ORDER_TYPE_FILLING)SetTypeFillingBySymbol(_Symbol);
  
  // 4.2 订单设置相关属性
  request.symbol = sym;
  request.comment = comment;  // 7
  request.magic = magic;  // 8
  
  // 4.3 价格相关属性
  request.volume = volume; // 3
  if(type == 0)request.price = sym_info.ask;
  else if(type == 1)request.price = sym_info.bid;
  
  request.sl = stop_loss; // 4
  request.tp = take_profit;  // 5
  request.deviation = deviation;  // 6
 
  // 请求发送成功
  bool is_ok = OrderSend(request, result);
  if(is_ok)
  {
    printf("状态码:%d, 订单号: %d, 开仓价: %.5f, 下单手数: %.2f, 交易返回注释: %s"
             ,
             result.retcode,
             result.deal,
             result.price,
             result.volume,
             result.comment
           );
    return true;
  }
  else
  {
    printf("发送交易请求失败,错误代码: %d, Return Code, %d", GetLastError(), result.retcode);
    // 重置错误代码
    ResetLastError();
    return false;
  }
  return false;
}
// 自动跟踪止损组件
bool moveSLTPProfit(const string symbol,
                    const int type,
                    const int sl,
                    const int tp,
                    const ulong magic
)
{
    int len  = PositionsTotal();
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    PositionInfo pos_info;
    for(int i=0; i<len; i++)
    {
      // 如果订单没找到直接跳过该订单
      if(!getPositionInfo(i,pos_info)) continue;
      // 订单获取成功
      printf("找到订单了!");
      if(type == 0){
        if(pos_info.sl <= ask - sl * point){
          moveSLTP(pos_info, symbol, type, ask, sl, tp,magic);
        }
            
      }
        
      else if(type == 1) 
        if(pos_info.sl >= bid + sl *point)
          moveSLTP(pos_info, symbol, type, bid, sl, tp,magic);
      
      
    }
  return false;
  
}
// 更新订单组件
void UpdatePosition(const string symbol,
                   const int type,
                   const double price,
                   const int sl,
                   const int tp,
                   const ulong magic

)
{
   int len = PositionsTotal();
   PositionInfo pos_info;
   for(int i=0;i<len;i++)
   {
     // 如果订单没找到直接跳过该订单
     if(!getPositionInfo(i,pos_info)) continue;
     moveSLTP(pos_info, symbol, type, price, sl, tp,magic);
  
   }
}

// 止损止盈条件过滤组件
bool moveSLTP(PositionInfo & position_info,
              const string symbol,
              const int type,
              const double price,
              const int sl,
              const int tp,
              const ulong magic

)
{
  // 1 校验货币对名称是否存在
  string m_sym = valSymbol(symbol);
  if(m_sym == "") return false;
  
  // 2 判断magic, symbol, type
  //if(position_info.magic == magic && position_info.symbol == symbol &&
  //  position_info.type == type){}
  // printf("进入");
  if(position_info.magic != magic) return false;
  if(position_info.symbol != symbol) return false;
  if(position_info.type != type) return false;
  
  // 3 判断sl和tp是否合法
  double m_sl = valStopLossPrice(symbol, type, price, sl);
  double m_tp = valTakeProfitPrice(symbol, type, price,tp);
  
  // 4 判断用户输入逻辑是否合法
  if(position_info.sl == m_sl && position_info.tp == m_tp) return false;
  // 4.1假如 sl和tp 都设置为0 不修改订单
  if(m_sl == 0.0 && m_tp == 0.0) return false;
  // 4.2假如 sl设置新的止损价 和 tp 默认为0 只修改止损
  else if(m_sl != position_info.sl && m_tp == 0)
    return moveSLTPBase(position_info.ticket, symbol, m_sl, position_info.tp,magic);
  // 4.3假如 sl默认为0 和 tp 设置新的止盈价 只修改止盈
  else if(m_sl == 0 && m_tp != position_info.tp)
    return moveSLTPBase(position_info.ticket, symbol, position_info.sl, m_tp,magic);
  // 4.4假如 sl设置新的止盈价 和 tp 设置新的止盈价 修改止损和止盈
  else if(m_sl != position_info.sl && m_tp != position_info.tp)
    return moveSLTPBase(position_info.ticket, symbol, m_sl,m_tp,magic);
  
  
  return false;
}
// 止损止盈的基础请求组件
bool moveSLTPBase(const ulong ticket,
                  const string symbol,
                  const double stop_loss,
                  const double take_profit,
                  const ulong magic

)
{
  // 1 初始化请求和返回响应体
  MqlTradeRequest request = {};
  MqlTradeResult result = {};
  
  // 2 设置发送请求修改操作属性
  request.action = TRADE_ACTION_SLTP;
  request.position = ticket;
  request.symbol = symbol;
  request.sl = stop_loss;
  request.tp = take_profit;
  request.magic = magic;
  
  // 3 发送操作请求
  bool is_ok = OrderSend(request, result);
  if(is_ok) return true;
  else
  {
    printf("发送交易请求失败,错误代码: %d", GetLastError());
    // 重置错误代码
    ResetLastError();
    return false;
  }
  return false;
}


// 获取指定条件的持仓单数量
int getPositionCount(const string symbol, const int type, const ulong magic)
{
  int count = 0;
  PositionInfo pos_info;
  for(int i=0; i < PositionsTotal(); i++)
  {
    // 获取持仓单信息
    if(getPositionInfo(i, pos_info) == true)
      if(pos_info.magic == magic)
        if(pos_info.symbol == symbol)
          if(pos_info.type == type)
            count++;
          else if(type == 12)
            count++;
  }
  
  return count;
}



// 迭代平仓组件
bool PositionClose(const string symbol, const int type, const int deviation, const ulong magic)
{
  // 没有需要平仓的订单直接跳出函数
  if(getPositionCount(symbol, type, magic) == 0) return false;
  int len = PositionsTotal();
  PositionInfo pos_info;
  for(int i = len - 1; i >= 0; i--)
  // for(int i = 0; i < len; i++)
  {
    if(getPositionInfo(i,pos_info) == false) continue;
    if(pos_info.magic != magic) continue;
    if(pos_info.symbol != symbol) continue;
    if(type == 0) // 平多单
      PositionCloseBase(pos_info.ticket, pos_info.symbol, 0, pos_info.volume, deviation, magic);
    else if(type == 1) // 平空单
      PositionCloseBase(pos_info.ticket, pos_info.symbol, 1, pos_info.volume, deviation, magic);
    else if(type == 12) // 平所有订单
      PositionCloseBase(pos_info.ticket, pos_info.symbol, pos_info.type, pos_info.volume, deviation, magic);
      
  }
  return PositionClose(symbol,type,deviation,magic);
}

// while平仓组件 
bool PositionClose2(const string symbol, const int type, const int deviation, const ulong magic)
{
  // 没有需要平仓的订单直接跳出函数
  int count = getPositionCount(symbol, type, magic);
  // 如果还有没平的持仓单
  while(count > 0)
  {
    int len = PositionsTotal();
    PositionInfo pos_info;
    for(int i = len - 1; i >= 0; i--)
    // for(int i = 0; i < len; i++)
    {
      if(getPositionInfo(i,pos_info) == false) continue;
      if(pos_info.magic != magic) continue;
      if(pos_info.symbol != symbol) continue;
      if(type == 0) // 平多单
        PositionCloseBase(pos_info.ticket, pos_info.symbol, 0, pos_info.volume, deviation, magic);
      else if(type == 1) // 平空单
        PositionCloseBase(pos_info.ticket, pos_info.symbol, 1, pos_info.volume, deviation, magic);
      else if(type == 12) // 平所有订单
        PositionCloseBase(pos_info.ticket, pos_info.symbol, pos_info.type, pos_info.volume, deviation, magic);
        
    }
    
    count = getPositionCount(symbol, type, magic);
  }

  return PositionClose(symbol,type,deviation,magic);
}

// 基础平仓组件
bool PositionCloseBase(const ulong ticket,
                       const string symbol,
                       const int type,
                       const double volume,
                       const int deviation,
                       const ulong magic
)
{
  double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
  double bid = SymbolInfoDouble(symbol,SYMBOL_BID);
  // 初始化交易请求
  MqlTradeRequest resquet = {};
  MqlTradeResult result = {};
  // 填写请求参数
  resquet.action = TRADE_ACTION_DEAL;
  resquet.position = ticket;
  resquet.symbol = symbol;
  resquet.magic = magic;
  resquet.volume = volume;
  resquet.deviation = deviation;
  resquet.type_filling = (ENUM_ORDER_TYPE_FILLING)SetTypeFillingBySymbol(_Symbol);;
  if(type == 0) // 平多单
  {
    resquet.type = ORDER_TYPE_SELL;
    resquet.price = bid;
  }
  else if(type == 1)// 平空单
  {
    resquet.type = ORDER_TYPE_BUY;
    resquet.price = ask;
  }
  bool is_ok = OrderSend(resquet, result);
  if(is_ok == true) 
  {
    printf("平仓成功, 代码:%d",result.retcode);
    return true;
  }
  else
  {
    printf("平仓失败, 错误代码:%d",GetLastError());
    ResetLastError();
  }
  return false;
}

// 获取价格盈利
double getPositionTakeProfit(const string symbol, const int type, const long magic)
{
  double count = 0.0;
  PositionInfo pos_info;
  for(int i=0; i < PositionsTotal(); i++)
  {
    // 获取持仓单信息
    if(getPositionInfo(i, pos_info) == true)
      if(pos_info.magic == magic)
        if(pos_info.symbol == symbol)
          if(pos_info.type == type)
          {
              count+= pos_info.profit;
          }
          
  }
  
  return count;
}



//设置Order Filling Mode
int SetTypeFillingBySymbol(const string symbol)
  {
   ENUM_ORDER_TYPE_FILLING m_type_filling;
   uint filling=(uint)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
   if((filling&SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
     {
      m_type_filling=ORDER_FILLING_FOK;
      return(m_type_filling);
     }
   if((filling&SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
     {
      m_type_filling=ORDER_FILLING_IOC;
      return(m_type_filling);
     }
//---
   return(0);
  }


// 更新订单组件按价格来更新。不是按点数来。
void UpdatePositionPrice(const string symbol,
                   const int type,
                   const double price,
                   const double target_price,
                   const ulong magic

)
{
   int len = PositionsTotal();
   PositionInfo pos_info;
   int i_sl, i_tp;
   
   
   for(int i=0;i<len;i++)
   {
     // 如果订单没找到直接跳过该订单
     if(!getPositionInfo(i,pos_info)) continue;
     
     if(type==0)
     {
       i_tp = iValuetoPoint(target_price-pos_info.price);
       i_sl = i_tp;
     }
     else if(type == 1)
     {
       i_tp = iValuetoPoint(pos_info.price-target_price);
       i_sl = i_tp;     
     }
     
     moveSLTP(pos_info, symbol, type, pos_info.price, i_sl, i_tp,magic);
  
   }
}


//获取等效价格
double GetRealPrice(const int i_OrderType,const ulong i_magic, const string i_comments)
{
   double d_RealPrice  = 0.0;
   double d_TotalPrice = 0.0; //总价格
   double d_TotalLots  = 0.0; //总手数
   double d_CurrLots   = 0.0; //目标手数
   //d_RealPrice = d_TotalPrice/d_TotalLots
   //d_TotalPrice //所有当前订单的累加和
   //d_TotalLots  //历史订单手数+目标手数
   // 查询所有定单信息
   int len = PositionsTotal();
   for(int i=len -1 ; i>=0; i--)
   //for(int i=0 ; i<len; i++)
   {
     PositionInfo pos_info;
     getPositionInfo(i, pos_info);
     if(pos_info.type == i_OrderType)
     {
     /* //Test Result
     printf("定单号: %d, 开仓时间: %s, 交易品种: %s, 开仓价格: %f, 开仓手数: %f, \n sl: %f, tp: %f,注释: %s",
       pos_info.ticket,
       (string)pos_info.dt,
       pos_info.symbol,
       pos_info.price,
       pos_info.volume,
       pos_info.sl,
       pos_info.tp,
       pos_info.comment
       );*/
      d_TotalPrice = d_TotalPrice + pos_info.price*pos_info.volume;
      d_TotalLots  = d_TotalLots  + pos_info.volume;
      printf("总价：%f, 总手数：%f",d_TotalPrice,d_TotalLots);       
       
       
      }    
    } 
      

    d_RealPrice = d_TotalPrice/d_TotalLots;
    printf("总价: %f, 总手数: %f, 真实价格: %f",d_TotalPrice, d_TotalLots, d_RealPrice); 
      
   return d_RealPrice;
}