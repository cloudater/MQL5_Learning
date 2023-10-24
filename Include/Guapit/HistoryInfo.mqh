//+------------------------------------------------------------------+
//|                                                  HistoryInfo.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

struct HistoryInfo
{
   ulong ticket; // 交易订单号
   datetime time; // 交易操作时间
   ENUM_DEAL_TYPE type; // 交易订单类型
   double volume; // 交易订单数量
   double price ; // 交易订单价格
   double commission; // 交易订单手续费
   double swap; // 交易订单隔夜利息
   double profit; // 交易订单净利值
   ulong magic; // 交易订单识别码
   string symbol; // 交易订单品种
   string comment; // 交易订单的注释
   ENUM_DEAL_ENTRY entry; // 交易订单操作类型
   long position_id; // 订单唯一ID
   long order; // 交易成交号
};

bool getHistoryInfo(int index, HistoryInfo &historys)
{
   ulong m_ticket = HistoryDealGetTicket(index);
   return getHistoryInfoByTicket(m_ticket,historys);
} 

bool getHistoryInfoByTicket(ulong ticket, HistoryInfo &historys)
{
   historys.ticket = ticket;
   historys.time = (datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
   historys.type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket,DEAL_TYPE);
   historys.volume =  HistoryDealGetDouble(ticket,DEAL_VOLUME);
   historys.price = HistoryDealGetDouble(ticket,DEAL_PRICE);
   historys.commission = HistoryDealGetDouble(ticket,DEAL_COMMISSION);
   historys.swap = HistoryDealGetDouble(ticket,DEAL_SWAP);
   historys.profit = HistoryDealGetDouble(ticket,DEAL_PROFIT);
   historys.comment = HistoryDealGetString(ticket,DEAL_COMMENT);
   historys.magic = HistoryDealGetInteger(ticket,DEAL_MAGIC);
   historys.symbol = HistoryDealGetString(ticket,DEAL_SYMBOL);
   historys.entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
   historys.position_id = HistoryDealGetInteger(ticket,DEAL_POSITION_ID);
   historys.order = HistoryDealGetInteger(ticket,DEAL_ORDER);
   return true;
}