
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"


struct OrderInfo
{
  ulong ticket; // 挂单号
  datetime time; // 挂单设置时间
  int time_msc; // 挂单设置时间(秒)
  datetime expiration; // 挂单到期时间
  datetime time_done; // 挂单被取消的时间
  int time_done_msc; // 挂单被取消时间(秒)
  string symbol; // 挂单交易品种
  string comment; // 挂单注释
  int digits; // 挂单交易品种的小数点位数
  double point; // 挂单交易品种最小报价单位
  double volume; // 挂单手数
  double price; // 挂单价格
  double stop_price; // 回踩价格
  double price_current; // 当前市场价
  double sl; // 挂单止损价
  double tp; // 挂单止盈价
  int type; // 挂单方向
  ulong magic; // 挂单EA识别码
};

bool getOrderInfo(const int index, OrderInfo & order_info)
{
  if(index < 0) return false;
  ulong ticket = OrderGetTicket(index);
  
  return getOrderInfoByTicket(ticket,order_info);
}

bool getOrderInfoByTicket(const ulong ticket, OrderInfo & order_info)
{
  if(OrderSelect(ticket) == false) return false;
  order_info.ticket = OrderGetInteger(ORDER_TICKET);
  order_info.type = (int)OrderGetInteger(ORDER_TYPE);
  order_info.time = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
  order_info.time_msc = (int)OrderGetInteger(ORDER_TIME_SETUP_MSC);
  order_info.expiration = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
  order_info.time_done = (datetime)OrderGetInteger(ORDER_TIME_DONE);
  order_info.time_done_msc = (int)OrderGetInteger(ORDER_TIME_DONE_MSC);
  order_info.symbol = OrderGetString(ORDER_SYMBOL);
  order_info.comment = OrderGetString(ORDER_COMMENT);
  order_info.digits = (int)SymbolInfoInteger(order_info.symbol,SYMBOL_DIGITS);
  order_info.point = SymbolInfoDouble(order_info.symbol,SYMBOL_POINT);
  order_info.volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
  order_info.price = OrderGetDouble(ORDER_PRICE_OPEN);
  order_info.stop_price = OrderGetDouble(ORDER_PRICE_STOPLIMIT);
  order_info.price_current = OrderGetDouble(ORDER_PRICE_CURRENT);
  order_info.sl = OrderGetDouble(ORDER_SL);
  order_info.tp = OrderGetDouble(ORDER_TP);
  order_info.magic = (ulong)OrderGetInteger(ORDER_MAGIC);
  return true;
}


// 根据用户输入整数返回挂单类型
ENUM_ORDER_TYPE getOrderType(const int type)
{ 
   ENUM_ORDER_TYPE order_type;
   switch(type)
   {
      case 2:
         order_type = ORDER_TYPE_BUY_LIMIT;
         break;
      case 3:
         order_type = ORDER_TYPE_SELL_LIMIT;
         break;
      case 4:
         order_type = ORDER_TYPE_BUY_STOP;
         break;
      case 5:
         order_type = ORDER_TYPE_SELL_STOP;
         break;
      case 6:
         order_type = ORDER_TYPE_BUY_STOP_LIMIT;
         break;  
      case 7:
         order_type = ORDER_TYPE_SELL_STOP_LIMIT;
         break; 
      default:
         order_type = -1;
   }
   
   return order_type;
}

ENUM_ORDER_TYPE_TIME getOrderTimeType(const int time_type)
{
   ENUM_ORDER_TYPE_TIME order_time_type;
   switch(time_type)
   {
      case 1:
         order_time_type = ORDER_TIME_DAY;
         break;
      case 2:
         order_time_type = ORDER_TIME_SPECIFIED;
         break;
      case 3:
         order_time_type = ORDER_TIME_SPECIFIED_DAY;
         break;
      default:
         order_time_type = ORDER_TIME_GTC;
   }
   return order_time_type;
}

