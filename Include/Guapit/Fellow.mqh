
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Guapit/PositionInfo.mqh>
#include <Guapit/Trade.mqh>

//+------------------------------------------------------------------+
//| 跟单发送端                                                       |
//+------------------------------------------------------------------+

// 获取订单数据
int GetPositions(PositionInfo &positions_info[])
{
   int total = PositionsTotal();
   ArrayResize(positions_info,total,20);
   
   for(int i=0;i<total;i++)
   {
      if(!getPositionInfo(i,positions_info[i]))
         continue;
   }
   return total;
}

// 将订单数据转化成字符串
string PositionsToString(PositionInfo &positions_info[], string sep="")
{
   string dst = "";
   int total = ArraySize(positions_info);
   dst += (string)total + "$"; // \n
   for(int i=0;i<total;i++)
   {
      dst += (string)positions_info[i].ticket + ",";
      dst += (string)positions_info[i].dt  + ",";
      ClearSymbol(positions_info[i].symbol,sep);
      dst += positions_info[i].symbol  + ",";
      dst += (string)positions_info[i].type  + ",";
      dst += (string)positions_info[i].price  + ",";
      dst += (string)positions_info[i].volume  + ",";
      dst += (string)positions_info[i].sl  + ",";
      dst += (string)positions_info[i].tp  + ",";
      dst += positions_info[i].comment  + "$";
   }
   return dst;
}

// 去除订单的后缀
void ClearSymbol(string &symbol, string sep)
{
   StringReplace(symbol, sep,"");
}

// 保存订单数据
void SaveToFile(string file_name,string positions_string)
{
    if(positions_string == "") return;
    
    // 保存数据 FILE_COMMON 关键标记
    int file_handle = FileOpen(file_name,FILE_WRITE|FILE_SHARE_READ|FILE_REWRITE|
                               FILE_COMMON|FILE_CSV,"",CP_UTF8);
    if(file_handle != INVALID_HANDLE)
    {
       FileWrite(file_handle,positions_string);
       FileFlush(file_handle);
       FileClose(file_handle);
    }
}

//+------------------------------------------------------------------+
//| 跟单接收端                                                       |
//+------------------------------------------------------------------+

string LoadByFile(string file_name)
{
   string dst = "";
   
   int file_handle = FileOpen(file_name,FILE_READ|FILE_SHARE_READ|FILE_REWRITE|
                               FILE_COMMON|FILE_CSV,"",CP_UTF8);
   if(file_handle != INVALID_HANDLE)
   {
       while(!FileIsEnding(file_handle)) 
       {
          dst += FileReadString(file_handle);
          
       }
       FileClose(file_handle);
   }
   return dst;
}

// 将字符串重组为订单数据
int StringToPositions(string src, PositionInfo &positions_info[])
{
   
   string dst[];
   StringSplit(src,'$',dst);
   int total = ArraySize(dst);
   // ArrayPrint(dst);
   if(total < 2) return 0;
   // 获取跟单方单数
   int count = (int)dst[0];
   ArrayResize(positions_info,count,20);
   
   if(total > 2)
   {
      int sub_count = 0;
      for(int i=1;i<total-1;i++)
      {
         string sub_dst[];
         StringSplit(dst[i],',',sub_dst);
         // ArrayPrint(sub_dst);
         positions_info[sub_count].ticket = (ulong)sub_dst[0];
         positions_info[sub_count].dt = (datetime)sub_dst[1];
         positions_info[sub_count].symbol = sub_dst[2];
         positions_info[sub_count].type = (int)sub_dst[3];
         positions_info[sub_count].price = (double)sub_dst[4];
         positions_info[sub_count].volume = (double)sub_dst[5];
         positions_info[sub_count].sl = (double)sub_dst[6];
         positions_info[sub_count].tp = (double)sub_dst[7];
         positions_info[sub_count].comment = sub_dst[8];
         sub_count++;
      }
   }
   
   
   return count;
}

//+------------------------------------------------------------------+
//|   跟单交易程序                                                   |
//+------------------------------------------------------------------+

// 根据接受信号开仓
void FellowTrade(PositionInfo &positions_info[], long magic)
{
   int fellow_total = ArraySize(positions_info);
   int total = PositionsTotal();
   PositionInfo m_pos;
   // 遍历所有的跟单信号数据
   for(int i=0;i<fellow_total;i++)
   {
      bool is_find = false;
      // 遍历当前接收端持仓数据
      for(int j=0;j<total;j++)
      {
         if(!getPositionInfo(j, m_pos))
            continue;
            
         // 如果跟单信号和本地单的注释一样就跳过
         if(m_pos.comment == (string)positions_info[i].ticket)
         {
            is_find = true;
            break;
         }
      }
      
      // 如果没找到相同的订单就开仓
      if(is_find == false)
      {
          // 添加限制条件
          
          
          string m_symbol = GetSymbol(positions_info[i].symbol);
          ulong m_ticket = positions_info[i].ticket;
          double m_volume = positions_info[i].volume;
          double m_price = positions_info[i].price;
          double m_sl = positions_info[i].sl;
          double m_tp = positions_info[i].tp;
          // 如果本地也有发送端一样的品种就交易
          if(m_symbol != "")
          {
             if(positions_info[i].type == 0)
             {
                 PositionSendBase(m_symbol,0,m_volume,m_sl,m_tp,0,(string)m_ticket,magic);
             }
             else if(positions_info[i].type == 1)
             {
                 PositionSendBase(m_symbol,1,m_volume,m_sl,m_tp,0,(string)m_ticket,magic);
             }
          }
      }
   }
}

// 根据跟单的交易名称找到本地同样的名称
string GetSymbol(string symbol)
{
   string m_symbol = "";
   int total = SymbolsTotal(false);
   for(int i=0;i<total;i++)
   {
       string m_symbol_name = SymbolName(i,false);
       if(StringFind(m_symbol_name,symbol)>=0)
       {
          m_symbol = m_symbol_name;
          break;
       }
   }
   return m_symbol;
}


// 根据跟单信号平仓
void FellowClose(PositionInfo &positions_info[], long magic)
{
   int fellow_total = ArraySize(positions_info);
   int total = PositionsTotal();
   PositionInfo m_pos;
   
   for(int i=0;i<total;i++)
   {
      if(!getPositionInfo(i, m_pos))
            continue;
      bool is_find = false;
      
      for(int j=0;j<fellow_total;j++)
      {
          if(m_pos.comment == (string)positions_info[j].ticket)
          {
             is_find = true;
             break;
          }
      }
      // 没找到,说明发送方平仓了
      if(is_find == false)
      {
         PositionCloseBase(m_pos.ticket,
                           m_pos.symbol,
                           m_pos.type,
                           m_pos.volume,
                           0,
                           magic);
         
      }
   }
}


// 根据发送端信号修改止损止盈
void FellowUpdate(PositionInfo &positions_info[], long magic)
{
   int fellow_total = ArraySize(positions_info);
   int total = PositionsTotal();
   PositionInfo m_pos;
   // 遍历所有的跟单信号数据
   for(int i=0;i<fellow_total;i++)
   {
      // 遍历当前接收端持仓数据
      for(int j=0;j<total;j++)
      {
         if(!getPositionInfo(j, m_pos))
            continue;
            
         // 如果跟单信号和本地单的注释一样就跳过
         if(m_pos.comment == (string)positions_info[i].ticket)
         {
            string m_symbol = GetSymbol(positions_info[i].symbol);
            ulong m_ticket = positions_info[i].ticket;
            double m_volume = positions_info[i].volume;
            double m_price = positions_info[i].price;
            double m_sl = positions_info[i].sl;
            double m_tp = positions_info[i].tp;
            
            if(m_sl != m_pos.sl || m_tp != m_pos.tp)
            {
               moveSLTPBase(m_pos.ticket,
                            m_pos.symbol,
                            m_sl,
                            m_tp,
                            m_pos.magic);             
               
               
            }
            
            break;
         }
      }
      
   }
}