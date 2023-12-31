#property copyright "Copyright 2022, Author:阿龙."
#property link      "https://www.guapit.com"
#property description "MT5智能交易编程课程"
#property description "QQ: 8199231"
#property version   "1.00"
#include <KtChan/Symbols.mqh>
#include <KtChan/OrderInfo.mqh>


//Buy Limit挂单
bool BuyLimit(const string symbol, // 挂单交易品种
             const double price, // 挂单价格
             const double volume, // 挂单手数
             const int sl, // 挂单止损价
             const int tp, // 挂单止盈价
             const int devitation, // 挂单滑点值
             const int time_type, // 挂单到期模式
             const datetime exporation, // 挂单到期时间
             const double stop_limit, // 挂单回踩价
             const string comment, // 挂单注释
             const long magic, // 挂单EA识别码
             const bool is_async= false // 是否启用异步请求操作

)
{
   return OrderSendOne(symbol,2,price,volume,sl,tp,devitation,time_type,
             exporation,stop_limit,comment,magic,is_async);
}

//Sell Limit挂单
bool SellLimit(const string symbol, // 挂单交易品种
             const double price, // 挂单价格
             const double volume, // 挂单手数
             const int sl, // 挂单止损价
             const int tp, // 挂单止盈价
             const int devitation, // 挂单滑点值
             const int time_type, // 挂单到期模式
             const datetime exporation, // 挂单到期时间
             const double stop_limit, // 挂单回踩价
             const string comment, // 挂单注释
             const long magic, // 挂单EA识别码
             const bool is_async= false // 是否启用异步请求操作

)
{
   return OrderSendOne(symbol,3,price,volume,sl,tp,devitation,time_type,
             exporation,stop_limit,comment,magic,is_async);
}


//Buy stop挂单
bool BuyStop(const string symbol, // 挂单交易品种
             const double price, // 挂单价格
             const double volume, // 挂单手数
             const int sl, // 挂单止损价
             const int tp, // 挂单止盈价
             const int devitation, // 挂单滑点值
             const int time_type, // 挂单到期模式
             const datetime exporation, // 挂单到期时间
             const double stop_limit, // 挂单回踩价
             const string comment, // 挂单注释
             const long magic, // 挂单EA识别码
             const bool is_async= false // 是否启用异步请求操作

)
{
   return OrderSendOne(symbol,4,price,volume,sl,tp,devitation,time_type,
             exporation,stop_limit,comment,magic,is_async);
}

//Sell stop挂单
bool SellStop(const string symbol, // 挂单交易品种
             const double price, // 挂单价格
             const double volume, // 挂单手数
             const int sl, // 挂单止损价
             const int tp, // 挂单止盈价
             const int devitation, // 挂单滑点值
             const int time_type, // 挂单到期模式
             const datetime exporation, // 挂单到期时间
             const double stop_limit, // 挂单回踩价
             const string comment, // 挂单注释
             const long magic, // 挂单EA识别码
             const bool is_async= false // 是否启用异步请求操作

)
{
   return OrderSendOne(symbol,5,price,volume,sl,tp,devitation,time_type,
             exporation,stop_limit,comment,magic,is_async);
}

//Buy stop Limit挂单
bool BuyStopLimit(const string symbol, // 挂单交易品种
             const double price, // 挂单价格
             const double volume, // 挂单手数
             const int sl, // 挂单止损价
             const int tp, // 挂单止盈价
             const int devitation, // 挂单滑点值
             const int time_type, // 挂单到期模式
             const datetime exporation, // 挂单到期时间
             const double stop_limit, // 挂单回踩价
             const string comment, // 挂单注释
             const long magic, // 挂单EA识别码
             const bool is_async= false // 是否启用异步请求操作

)
{
   return OrderSendOne(symbol,6,price,volume,sl,tp,devitation,time_type,
             exporation,stop_limit,comment,magic,is_async);
}

//Sell stop Limit挂单
bool SellStopLimit(const string symbol, // 挂单交易品种
             const double price, // 挂单价格
             const double volume, // 挂单手数
             const int sl, // 挂单止损价
             const int tp, // 挂单止盈价
             const int devitation, // 挂单滑点值
             const int time_type, // 挂单到期模式
             const datetime exporation, // 挂单到期时间
             const double stop_limit, // 挂单回踩价
             const string comment, // 挂单注释
             const long magic, // 挂单EA识别码
             const bool is_async= false // 是否启用异步请求操作

)
{
   return OrderSendOne(symbol,7,price,volume,sl,tp,devitation,time_type,
             exporation,stop_limit,comment,magic,is_async);
}

// 挂单操作组件
bool OrderSendOne(const string symbol, // 挂单交易品种
                   const int type, // 挂单类型
                   const double price, // 挂单价格
                   const double volume, // 挂单手数
                   const int sl, // 挂单止损价
                   const int tp, // 挂单止盈价
                   const int devitation, // 挂单滑点值
                   const int time_type, // 挂单到期模式
                   const datetime exporation, // 挂单到期时间
                   const double stop_limit, // 挂单回踩价
                   const string comment, // 挂单注释
                   const long magic, // 挂单EA识别码
                   const bool is_async= false // 是否启用异步请求操作

)
{
  
//  string m_symbol = valSymbol(symbol);
  string m_symbol = _Symbol; 
  if(m_symbol == NULL) return false;
  
  if(isOrder(m_symbol, type, comment, magic) == true)
    return false;
  
  double m_price = valPrice(m_symbol,type,price,stop_limit);
  if(m_price == 0.0) return false;
  
  double m_sl = valSL(m_symbol, type, m_price, sl);
  double m_tp = valTP(m_symbol, type, m_price, tp);
  
  return OrderSendBase(m_symbol,type,price,volume,m_sl,m_tp,devitation,time_type,
                       exporation,stop_limit,comment,magic,is_async);
}

// 挂单基础函数组件
bool OrderSendBase(const string symbol, // 挂单交易品种
                   const int type, // 挂单类型
                   const double price, // 挂单价格
                   const double volume, // 挂单手数
                   const double stop_loss, // 挂单止损价
                   const double take_profit, // 挂单止盈价
                   const int devitation, // 挂单滑点值
                   const int time_type, // 挂单到期模式
                   const datetime exporation, // 挂单到期时间
                   const double stop_limit, // 挂单回踩价
                   const string comment, // 挂单注释
                   const long magic, // 挂单EA识别码
                   const bool is_async= false // 是否启用异步请求操作

)
{
   // 1.初始化挂单请求结构体
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   // 2. 设置发送相关配置
   request.action = TRADE_ACTION_PENDING;
   request.type = getOrderType(type);
   request.type_time = getOrderTimeType(time_type);
   request.type_filling = ORDER_FILLING_IOC;
   // 3. 挂单相关配置
   request.symbol = symbol;
   request.comment = comment;
   request.magic = magic;
   // 4. 挂单价格相关配置
   request.price = price;
   request.volume = volume;
   request.sl = stop_loss;
   request.tp = take_profit;
   request.deviation = devitation;
   request.expiration = exporation;
   request.stoplimit =stop_limit;
   
   bool is_ok = false;
   if(is_async == false)
   {
      is_ok = OrderSend(request, result);
   }
   else
   {
      is_ok = OrderSendAsync(request, result);
   }
   
   if(!is_ok)
   {
      printf("发送挂单请求失败, 错误代码: %d", GetLastError());
      ResetLastError();
      return false;
   }
   
   return is_ok;
}

/*
// 验证交易品种名称
string valSymbol(const string symbol)
{
   if(symbol == "" || symbol == NULL)
   {
     return _Symbol;
   }
   else
   {
      if(!SymbolSelect(symbol,true))
      {
         return NULL;
      }
   }
   
   return symbol;
}
*/

// 验证价格是否合法
double valPrice(const string symbol, const int type,const double price, const double stop_limit)
{
   double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   ENUM_ORDER_TYPE order_type = getOrderType(type);
   if(order_type == ORDER_TYPE_BUY_LIMIT) // Buy: 抄底方向 ↘
   {
     if(price < ask) // 90 < 100
     {
       return price;
     }
   }
   else if(order_type == ORDER_TYPE_SELL_LIMIT) // Sell: 抄底方向 ↗
   {
     if(price > bid) // 110 > 100
     {
       return price;
     }
   }
   else if(order_type == ORDER_TYPE_BUY_STOP) // Buy: 突破方向↗
   {
     if(price > ask)
     {
       return price;
     }
   }
   else if(order_type == ORDER_TYPE_SELL_STOP) // Sell: 突破方向↘
   {
     if(price < bid) // 90 < 100
     {
       return price;
     }
   }
   
   else if(order_type == ORDER_TYPE_BUY_STOP_LIMIT) // Buy: 突破方向↗
   {
     if(price > ask && price > stop_limit) // 110 > 100 && 110 > 90
     {
       return price;
     }
   }
   
   else if(order_type == ORDER_TYPE_SELL_STOP_LIMIT) // sell: 突破方向↘
   {
     if(price < bid && price < stop_limit) // 90 < 100 && 90 < 95
     {
       return price;
     }
   }
   return 0.0;
}


// 验证止损组件
double valSL(const string symbol, const int type, const double price, const int sl)
{
  if(price <= 0.0 || sl <= 0) return 0.0;
  SymbolInfo m_sym;
  getSymbolInfo(symbol, m_sym);
  double m_sl_level=0.0;
  // sl: 20 > stops_level: 10
  int m_sl = sl > m_sym.stops_level ? sl : m_sym.stops_level;
  if(type % 2 == 0) // buy
  {
    m_sl_level = NormalizeDouble(price - m_sl * m_sym.point, m_sym.digits);
  }
  else if(type % 2 == 1) // sell
  {
    m_sl_level = NormalizeDouble(price + m_sl * m_sym.point, m_sym.digits);
  }
  return m_sl_level;
  
}

// 验证止损组件
double valTP(const string symbol, const int type, const double price, const int tp)
{
  if(price <= 0.0 || tp <= 0) return 0.0;
  SymbolInfo m_sym;
  getSymbolInfo(symbol, m_sym);
  double m_tp_level=0.0;
  // sl: 20 > stops_level: 10
  int m_tp = tp > m_sym.stops_level ? tp : m_sym.stops_level;
  if(type % 2 == 0) // buy
  {
    m_tp_level = NormalizeDouble(price + m_tp * m_sym.point, m_sym.digits);
  }
  else if(type % 2 == 1) // sell
  {
    m_tp_level = NormalizeDouble(price - m_tp * m_sym.point, m_sym.digits);
  }
  return m_tp_level;
  
}

// 查询指定挂单是否存在
bool isOrder(const string symbol, const int type, const string comment, const long magic)
{
    int total = OrdersTotal();
    printf("len: %d", total);
    OrderInfo order_info;
    bool is_order = false;
    for(int i=total - 1;i>=0;i--)
    {
       if(!getOrderInfo(i,order_info))
         continue;
       if(order_info.magic != magic)
         continue;
       if(order_info.symbol != symbol)
         continue;
       if(order_info.type != type)
         continue;
       if(order_info.comment == comment)
       {
         is_order = true;
         break;
       } 
       
     }
    
    return is_order;
}

// 将指定方向订单增加指定点数
bool OrderUpdateUp(const string symbol,
                 const int type,
                 const double price_step,
                 const int sl,
                 const int tp,
                 const int deviation,
                 const int time_type,
                 const datetime expirtion,
                 const double stop_limit,
                 const long magic,
                 const bool is_async=false

)
{
   OrderInfo m_order;
   int total = OrdersTotal();
   for(int i=total - 1;i>=0;i--)
   {
      if(!getOrderInfo(i, m_order))
        continue;
      if(m_order.magic != magic)
        continue;
      if(m_order.symbol != symbol)
        continue;
      if(m_order.type == type)
      {
         if(type % 2 == 0) // buy
         {
           double m_up = m_order.price + price_step * m_order.point;
           OrderUpdateOne(m_order.ticket,m_up,sl,tp,deviation,
             time_type,expirtion,stop_limit,is_async);
         }
         else if(type % 2 == 1) // sell
         {
           double m_up = m_order.price - price_step * m_order.point;
           OrderUpdateOne(m_order.ticket,m_up,sl,tp,deviation,
             time_type,expirtion,stop_limit,is_async);
         }
         
      }
         
      
   }
   return true;
}


// 将指定方向订单增加指定点数
bool OrderUpdateDown(const string symbol,
                 const int type,
                 const double price_step,
                 const int sl,
                 const int tp,
                 const int deviation,
                 const int time_type,
                 const datetime expirtion,
                 const double stop_limit,
                 const long magic,
                 const bool is_async=false

)
{
   OrderInfo m_order;
   int total = OrdersTotal();
   for(int i=total - 1;i>=0;i--)
   {
      if(!getOrderInfo(i, m_order))
        continue;
      if(m_order.magic != magic)
        continue;
      if(m_order.symbol != symbol)
        continue;
      if(m_order.type == type)
      {
         if(type % 2 == 0) // buy
         {
           double m_up = m_order.price - price_step * m_order.point;
           OrderUpdateOne(m_order.ticket,m_up,sl,tp,deviation,
             time_type,expirtion,stop_limit,is_async);
         }
         else if(type % 2 == 1) // sell
         {
           double m_up = m_order.price + price_step * m_order.point;
           OrderUpdateOne(m_order.ticket,m_up,sl,tp,deviation,
             time_type,expirtion,stop_limit,is_async);
         }
         
      }
         
      
   }
   return true;
}

// 群改挂单
bool OrderUpdateAll(const string symbol,
                 const int type,
                 const double price,
                 const int sl,
                 const int tp,
                 const int deviation,
                 const int time_type,
                 const datetime expirtion,
                 const double stop_limit,
                 const long magic,
                 const bool is_async=false

)
{
   OrderInfo m_order;
   int total = OrdersTotal();
   for(int i=total - 1;i>=0;i--)
   {
      if(!getOrderInfo(i, m_order))
        continue;
      if(m_order.magic != magic)
        continue;
      if(m_order.symbol != symbol)
        continue;
      if(m_order.type == type)
      {
         OrderUpdateOne(m_order.ticket,price,sl,tp,deviation,
             time_type,expirtion,stop_limit,is_async);
      }
         
      
   }
   return false;
}


bool OrderUpdate(const string symbol,
                 const int type,
                 const string comment,
                 const double price,
                 const int sl,
                 const int tp,
                 const int deviation,
                 const int time_type,
                 const datetime expirtion,
                 const double stop_limit,
                 const long magic,
                 const bool is_async=false

)
{
   OrderInfo m_order;
   int total = OrdersTotal();
   for(int i=total - 1;i>=0;i--)
   {
      if(!getOrderInfo(i, m_order))
        continue;
      if(m_order.magic != magic)
        continue;
      if(m_order.symbol != symbol)
        continue;
      if(m_order.type != type)
        continue;
      if(m_order.comment == comment)
      {
         return OrderUpdateOne(m_order.ticket,price,sl,tp,deviation,
             time_type,expirtion,stop_limit,is_async);
      }
   }
   return false;
}

// 根据订单号,修改指定订单
bool OrderUpdateOne(const ulong ticket,
                     const double price,
                     const int sl,
                     const int tp,
                     const int deviation,
                     const int time_type,
                     const datetime expirtion,
                     const double stop_limit,
                     const bool is_async=false

)
{
   OrderInfo m_order;
   if(!getOrderInfoByTicket(ticket, m_order))
      return false;
   
   double m_price = valPrice(m_order.symbol, m_order.type, price, stop_limit);
   if(m_price == 0.0) m_price = m_order.price;
   
   double m_sl = valSL(m_order.symbol, m_order.type, m_price, sl);
   if(m_sl == 0.0) m_sl = m_order.sl;
   
   double m_tp = valTP(m_order.symbol, m_order.type, m_price, tp);
   if(m_tp == 0.0) m_tp = m_order.tp;
  
   return OrderUpdateBase(m_order.ticket,m_order.symbol,price,m_sl,m_tp,
             deviation,time_type,expirtion,stop_limit,is_async);
   
   // return OrderUpdateBase(ticket,)
}
  
// 修改挂单基础组件
bool OrderUpdateBase(const ulong ticket,
                     const string symbol,
                     const double price,
                     const double stop_loss,
                     const double take_profit,
                     const int deviation,
                     const int time_type,
                     const datetime expirtion,
                     const double stop_limit,
                     const bool is_async=false

)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_MODIFY;
   request.type_time = getOrderTimeType(time_type);
   request.order = ticket;
   request.symbol = symbol;
   request.price = price;
   request.sl = stop_loss;
   request.tp = take_profit;
   request.deviation = deviation;
   request.expiration = expirtion;
   request.stoplimit = stop_limit;
   
   bool is_ok = false;
   if(is_async == false)
   {
      is_ok = OrderSend(request, result);
   }
   else
   {
      is_ok = OrderSendAsync(request, result);
   }
   
   if(!is_ok)
   {
      printf("发送挂单请求失败, 错误代码: %d", GetLastError());
      ResetLastError();
      return false;
   }
   
   return is_ok;
   
}