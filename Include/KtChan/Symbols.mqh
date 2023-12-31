//+------------------------------------------------------------------+
//|  交易信息函数库                                                  |
//+------------------------------------------------------------------+

// 1. 创建交易品种信息结构体
struct SymbolInfo
{
  double ask; // buy方向报价
  double bid; // sell方向报价
  double point; // 最小报价单位
  int digits; // 小数点的位数
  int spread; // 点差
  ENUM_ORDER_TYPE_FILLING filling_mode; // 订单模式
  int stops_level; // 止损价和报价之间最小的间距点数
  double tick_value; // 每点价值
};

// 2. 获取指定交易品种的信息
bool getSymbolInfo(const string symbol, SymbolInfo & symbol_info)
{
  bool is_exsit = SymbolSelect(symbol,true);
  if(is_exsit)
  {
    symbol_info.ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    symbol_info.bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    symbol_info.point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    symbol_info.digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    symbol_info.spread = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
    //symbol_info.filling_mode = 
    //  (ENUM_ORDER_TYPE_FILLING)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
    symbol_info.filling_mode = ORDER_FILLING_FOK;
    symbol_info.stops_level = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);  
    symbol_info.tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    
  }
  return is_exsit;
}