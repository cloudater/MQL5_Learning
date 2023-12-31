//+------------------------------------------------------------------+
//|  定单信息统计函数组件库                                          |
//+------------------------------------------------------------------+

struct PositionInfo
{
  ulong ticket; // 定单号
  datetime dt; // 定单开仓时间
  string symbol; // 定单交易品种
  string comment; // 定单注释
  int digits; // 定单交易品种的小数点位数
  double volume; // 定单手数
  double price; // 定单价格
  double sl; // 定单止损价
  double tp; // 定单止盈价
  double swap; // 定单手续费
  double profit; // 盈利值
  int type; // 定单方向
  ulong magic;
};

// 获取指定序号的定单信息组件
bool getPositionInfo(const int index, PositionInfo& position_info)
{
  // 1.验证数据是否正常
  if(index < 0) return false;
  ulong m_ticket = PositionGetTicket(index);
  // 2.验证通过,获取定单数据
  return getPositionInfoByTicket(m_ticket,position_info);
}

// 获取指定订单号的定单信息组件
bool getPositionInfoByTicket(const ulong ticket, PositionInfo& position_info)
{
  if(!PositionSelectByTicket(ticket)) return false;
  // 2.验证通过,获取定单数据
  position_info.ticket = PositionGetInteger(POSITION_TICKET);
  position_info.dt = (datetime)PositionGetInteger(POSITION_TIME);
  position_info.symbol = PositionGetString(POSITION_SYMBOL);
  position_info.digits = (int)SymbolInfoInteger(position_info.symbol, SYMBOL_DIGITS);
  position_info.price = PositionGetDouble(POSITION_PRICE_OPEN);
  position_info.sl = PositionGetDouble(POSITION_SL);
  position_info.tp = PositionGetDouble(POSITION_TP);
  position_info.swap = PositionGetDouble(POSITION_SWAP);
  position_info.profit = PositionGetDouble(POSITION_PROFIT);
  position_info.volume = PositionGetDouble(POSITION_VOLUME);
  position_info.comment = PositionGetString(POSITION_COMMENT);
  position_info.type = (int)PositionGetInteger(POSITION_TYPE);
  position_info.magic = PositionGetInteger(POSITION_MAGIC);
  return true;
}

