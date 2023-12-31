//+------------------------------------------------------------------+
//|                                                   CCI_ATR_EA.mq5 |
//| https://youtu.be/PFYA-WSwWh8?si=uhwkubR5chEDo5wJ                 |
//|逆势交易策略 36 18 54 108
// 1. CCI交叉
// 2. ATR 6倍止损止盈                                                 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

//2023.10.13 Bug太多。V1.00 未release
//2023.10.19 V1.00 Release demo running
//2023.10.20 发现一个bug。EA模拟可以跑。可是EA里面不会自动平仓。
//因为现在是我做了一个补仓脚本。等于初始化了一下。现在，把初始化放到EA里面试试看。
//2023.10.31 打算修复一个BUG。就是平仓好像有BUG。经常发现没有在应该平仓的时候平仓。 SOL0001
//2023.11.1 31日BUG没修复。先修复一个。任何交叉时候，两条线不能同时低于CCI 200,-200。如果同时在区间内，大概率不会反转。SOL0002
//SOL0002,不用上线。经过测试，多条件以后效果更差。因为，你为什么选200和-200呢？对吧？
//SOL0001 发现问题，如果FAST=SLOW的时候，可能1-2条H1。这种情况，没有认为是交叉。试试>=。
//SOL0003,发现没有自动关单。可能是每次reset_status+EA重启以后，状态不对了。
//SOL0003-1，打算用保存参数的方式修复SOL0003的BUG
//SOL0004,发现保存s参数的时候，只能做一个品种。因为没有做品种的判断。我考虑是要做一个判断还是做多个文件。
//SOL0005,发现一个重大的bug。系统CopyBuffer的时候，自己定义的D_CCI,画图是对的，可是CopyBuffer数值不对。
//为此，暂时用iCCI来取代D_CCI。
//SOL0005找到原因了。CopyBuffer的时候，使用了PRICE_CLOSE。可是画图用的是PRICE_TPICAL，所以，不影响
//iCustom的时候，需要加PRICE_TYPICAL
//SOL0006增加一个i_errcount，计算失败次数。如果失败了。3次就退出。好像CLOSE的时候还有这个问题。暂时先不处理了。
//SOL0007发现不会自动平仓。经过检查，发现下单以后is_buy, is_sell, is_trigger有冲突。比如，下多单is_buy=false, is_trigger=false。这个时候，就无法进入positionclose模块。
//SOL0007如果positions>0，则is_trigger需要修正一下。

#include <Guapit/Trade.mqh>

enum OrderType{
  BuyType, // Buy方向 0
  SellType // Sell方向 1
};

//SOL0003-1
struct Params
{
  bool is_buy;
  bool is_sell;
  bool is_trigger;
};

Params is_param;
string param_file_name;
//SOL0003-1

//参数设置
input string div1 = "--------指标设置--------"; // 分割线
input int init_fast_period = 18; // CCI快线周期
input int init_fast_color = clrWhite; //CCI快线颜色
input int init_slow_period = 54; // CCI慢线周期
input int init_slow_color = clrYellow; //CCI慢线颜色
input bool is_ATR=true; //是否打开ATR止盈止损;


input string div2 = "--------EA设置--------"; // 分割线
input double init_lots = 0.01; // 下单手数
input string init_comment = "CCI crose+ATR EA: "; // 注释前缀
input long init_magic = 15291406; // EA识别码
input int init_tp = 500; //止盈
input OrderType init_type = BuyType; // 设置开仓方向
input string init_savefile = "is_param.csv";//参数文件的名称




// 全局变量配置
bool is_buy = false;
int buy_count = 0;
string buy_before;
double buyCCI=0.0;

bool is_sell = false;
int sell_count = 0;
string sell_before;
double sellCCI=0.0;

int g_errcount = 0;

//设置变量
SymbolInfo ea_symbol_info;
PositionInfo ea_pos_info;
string ea_comment;
bool is_trade;
int ea_tp=0;
int ea_sl=0;
double max_ccifast=0.0;
int max_cciidx=0;
double min_ccifast=0.0;
int min_cciidx=0;

//设置指标Handle
int D_CCIHandle;
int ATRHandle;
double FastCCI[]; // 快速趋势线数组
double SlowCCI[]; // 慢速趋势线数组
double iATRBuffer[]; //ATR数组

bool is_trigger = false; //用来判断是否可以开仓平仓。避免反复开仓平仓的问题。


//EA中OnTick使用的数组
int copied;
double ArrayClose[];
double ArrayOpen[];
double ArrayHigh[];
double ArrayLow[];

int OnInit()
  {

//SOL0003-1
      // 定义文件名
   param_file_name = init_savefile;
   // 判断文件是否存在
   if(!FileIsExist(param_file_name))
   {
      Save(param_file_name,is_param);
   }
   else // 如果文件存在就读取内容
   {
     Load(param_file_name,is_param);
   }
   // 把读取到的参数重新赋值
   is_buy = is_param.is_buy;
   is_sell = is_param.is_sell;
   is_trigger = is_param.is_trigger;
//SOL0003-1



   D_CCIHandle = iCustom(_Symbol,PERIOD_CURRENT,"KtChan/D_CCI",init_fast_period,init_slow_period,PRICE_TYPICAL);

   ATRHandle=iATR(_Symbol,PERIOD_CURRENT,108);
   if(ATRHandle==INVALID_HANDLE) 
   { 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d", 
                  "iATR", 
                  EnumToString(PERIOD_CURRENT), 
                  GetLastError()); 
      return(INIT_FAILED); 
   } 
   //ChartIndicatorAdd(0,subwindow, CCISlowHandle);
   //printf("CCIFastHandle: %d", CCIFastHandle);
   //printf("CCISlowHandle: %d", CCISlowHandle);
     
   //CopyBuffer(CCIFastHandle,0,0,10,FastCCI);
   //ArraySetAsSeries(FastCCI,true);
   //ArrayPrint(FastCCI); 
   
   //先判断前24组CCIFast中，有没有触发-200和+200的线，如果有。就设置参数。
   //用来启动。因为一开始介入的时候，时机没那么好。
   //-----------------------------开始-----------------------//
   CopyBuffer(D_CCIHandle,0,0,24,FastCCI); 
   ArraySetAsSeries(FastCCI,true);
   max_cciidx = Highest(FastCCI,23,23);
   min_cciidx = Lowest(FastCCI,23,23);
   max_ccifast = FastCCI[max_cciidx];
   min_ccifast = FastCCI[min_cciidx];


   buy_count = getPositionCount(_Symbol,0,init_magic);
   sell_count = getPositionCount(_Symbol,1,init_magic);   
   
   if(max_ccifast >200.00 || min_cciidx < -200.00)
   {
      if(max_cciidx < min_cciidx)
      {
         buyCCI = FastCCI[max_cciidx];
         is_buy = true;
         is_sell = false;
         if(buy_count + sell_count == 0) is_trigger = true; //      
      }
      else if (max_cciidx > min_cciidx)
      {
         sellCCI = FastCCI[min_cciidx];
         is_buy = false;
         is_sell = true; 
          if(buy_count + sell_count == 0) is_trigger = true; //    
      }
      else
      {
         printf("min cci = max cci");
      }
   }
   //----------------------------结束------------------------//
   // 组合订单注释前缀
   buy_before  = " Buy ";
   sell_before = " Sell ";
   
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
     //--- 获得EA卸载的原因
     Print(__FUNCTION__," EA已经卸载, 发生卸载的原因代码: ",reason); 
     //--- 获得EA重新初始化原因注解, 也可以使用常量函数: _UninitReason
     Print(__FUNCTION__," 卸载原因说明: ",getUninitReasonText(UninitializeReason()));
     is_param.is_buy=is_buy;
     is_param.is_sell = is_sell;
     is_param.is_trigger = is_trigger;
     Save(param_file_name,is_param);
  }

void OnTick()
  {

     // 1.检查当前交易环境是否允许交易
     is_trade = isTrade();
     if(is_trade == false) return;
     // 获取当前指定品种信息
     getSymbolInfo(_Symbol,ea_symbol_info);
     
     buy_count = getPositionCount(_Symbol,0,init_magic);
     sell_count = getPositionCount(_Symbol,1,init_magic);
     
     
     CopyBuffer(D_CCIHandle,0,0,10,FastCCI);
     CopyBuffer(D_CCIHandle,1,0,10,SlowCCI);


     ArraySetAsSeries(FastCCI,true);
     ArraySetAsSeries(SlowCCI,true);
     
     CopyBuffer(ATRHandle,0,0,10, iATRBuffer);
     ArraySetAsSeries(iATRBuffer,true);
     

     copied = CopyClose(_Symbol,PERIOD_CURRENT,0,10, ArrayClose);
     copied = CopyOpen(_Symbol,PERIOD_CURRENT,0,10, ArrayOpen);
     copied = CopyHigh(_Symbol,PERIOD_CURRENT,0,20, ArrayHigh);
     copied = CopyLow(_Symbol,PERIOD_CURRENT,0,20, ArrayLow);
     ArraySetAsSeries(ArrayClose,true);
     ArraySetAsSeries(ArrayOpen,true);
     ArraySetAsSeries(ArrayHigh,true);
     ArraySetAsSeries(ArrayLow,true);
     
     if(is_buy == false && (FastCCI[1] < -200.00) ) //当快线低于-200时，多头信号打开
     {
        
        buyCCI = FastCCI[1];
        is_buy = true;
        is_sell = false;
        is_trigger = true;
     }
     else if(is_sell == false && (FastCCI[1] > 200.00) ) //当快线高于200时，空头信号打开
     {
        sellCCI = FastCCI[1];
        is_buy = false;
        is_sell = true;
        is_trigger = true;
     }     
     else
     {
     
     }
     
     //SOL0007
     //SOL0007增加以后，收益降低很多。所以先不用了。
     //可能因为提早出局，反而走的不好。先不用这个版本。
     //这个有个悖论。如果全部遵守规则，会安全。收益降低。
     //2023.12.10 我打算还是先打开这个功能。因为安全第一。而且，不要违法规则。
     
     if(buy_count > 0)
       if(is_trigger == false && (FastCCI[1] > 200.00) ) //当快线高于200时，空头平仓信号打开
       {
          sellCCI = FastCCI[1];
          is_trigger = true;
       }
     if(sell_count > 0)
       if(is_trigger == false && (FastCCI[1] < -200.00) ) //当快线低于-200时，多头平仓信号打开
       {
          buyCCI = FastCCI[1];
          is_trigger = true;
       }     
      
     
     


     if(reset_status() == true) 
     {
       //NULL
     };     
     
     if(sell_count > 0 || buy_count ==0) //有空单或者多单为空的情况
     {
     if(is_trigger == true 
     && is_buy == true 
     //&& (FastCCI[2]<SlowCCI[2] && FastCCI[1] > SlowCCI[1]) 
     && (FastCCI[2]<=SlowCCI[2] && FastCCI[1] >= SlowCCI[1]) //SOL0001
     //&& !((FastCCI[0] > 200 || FastCCI[0] < -200) && (SlowCCI[0] > 200 || SlowCCI[0] < -200)) //SOL00002
     ) //快线上穿慢线的时候，平空买多。
     {

        // 获取指定条件的持仓单数量实例
        int count = getPositionCount(_Symbol, 1, init_magic);
        printf("当前持空仓单数: %d",count);
        // 平仓测试
        // PositionClose(_Symbol, 12, 10, 0);
        if(PositionClose2(_Symbol, 1, 10, init_magic)) sell_count = 0; //平空       
        ea_comment = init_comment + buy_before + DoubleToString(buyCCI);
        if(is_ATR == true)
        {
           ea_sl=iValuetoPoint(iATRBuffer[0]*6); //ATR当前值的6倍，设置止赢，止损
           ea_tp=ea_sl;
        }      
        if(BuyAdd(_Symbol,init_lots,ea_sl,ea_tp,5,ea_comment,init_magic)) //开多
        {
           is_sell = true;
           is_buy = false;
           is_trigger = false; //成功以后，除非重新触发，否则就是false. 
           g_errcount = 0; //重置状态		   
        }
		else
		{
		   g_errcount = g_errcount +1;
		   if (g_errcount >3)
		   {
            printf("Order error more than 3 times, return!");
			   return;
		   }
		}
     }
     }
     

     
     
     if(buy_count > 0 || sell_count == 0) //有多单或者空单为空的情况
     {
     if(is_trigger == true 
     && is_sell == true 
     //&& (FastCCI[2]>SlowCCI[2] && FastCCI[1] < SlowCCI[1])
     && (FastCCI[2]>=SlowCCI[2] && FastCCI[1] <= SlowCCI[1]) //SOL0001
     //&& !((FastCCI[0] > 200 || FastCCI[0] < -200) && (SlowCCI[0] > 200 || SlowCCI[0] < -200)) //SOL00002
     ) //快线下穿慢线的时候，平多买空。
     {

        // 获取指定条件的持仓单数量实例
        int count = getPositionCount(_Symbol, 0, init_magic);
        printf("当前持多仓单数: %d",count);
        // 平仓测试
        // PositionClose(_Symbol, 12, 10, 0);
        if(PositionClose2(_Symbol, 0, 10, init_magic)) buy_count = 0; //平多         
        ea_comment = init_comment + sell_before+DoubleToString(sellCCI);
        if(is_ATR == true)
        {
           ea_sl=iValuetoPoint(iATRBuffer[0]*6); //ATR当前值的6倍，设置止赢，止损
           ea_tp=ea_sl;
        }  
        
        if(SellAdd(_Symbol,init_lots,ea_sl,ea_tp,5,ea_comment,init_magic)) //开空
        {
           
           is_sell = false;
           is_buy = true;
           is_trigger = false; //成功以后，除非重新触发，否则就是false.
           g_errcount = 0; //重置状态		   
        }
		else
		{
		   g_errcount = g_errcount +1;
		   if (g_errcount >3)
		   {
			   printf("Order error more than 3 times, return!");
			   return;
		   }
		}
     }
     }
     
  }

string getUninitReasonText(int reasonCode) 
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

int iValuetoPoint(const double f_value) //价格变成点数
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pointValue = MathAbs(f_value)/point;
   int rt_point = MathCeil(MathAbs(pointValue));
   return rt_point;
}


int Highest(const double &array[],const int depth,const int start)
  {
   if(start<0)
      return(0);

   double max=array[start];
   int    index=start;
//--- start searching
   for(int i=start-1; i>start-depth && i>=0; i--)
     {
      if(array[i]>max)
        {
         index=i;
         max=array[i];
        }
     }
//--- return index of the highest bar
   return(index);
  }
//+------------------------------------------------------------------+
//|  Search for the index of the lowest bar                          |
//+------------------------------------------------------------------+
int Lowest(const double &array[],const int depth,const int start)
  {
   if(start<0)
      return(0);

   double min=array[start];
   int    index=start;
//--- start searching
   for(int i=start-1; i>start-depth && i>=0; i--)
     {
      if(array[i]<min)
        {
         index=i;
         min=array[i];
        }
     }
//--- return index of the lowest bar
   return(index);
  }
  
  
bool reset_status()
{
   int order_count = 0;
   order_count = getPositionCount(_Symbol,12,init_magic); //获取当前的订单数量
   
   if (order_count <= 0) //如果订单为0
   {
     CopyBuffer(D_CCIHandle,0,0,24,FastCCI);
     ArraySetAsSeries(FastCCI,true);
     max_cciidx = Highest(FastCCI,23,23);
     min_cciidx = Lowest(FastCCI,23,23);
     max_ccifast = FastCCI[max_cciidx];
     min_ccifast = FastCCI[min_cciidx];


     buy_count = getPositionCount(_Symbol,0,init_magic);
     sell_count = getPositionCount(_Symbol,1,init_magic);   
   
     if(max_ccifast >200.00 && min_ccifast < -200.00) 
     {
       if(max_cciidx > min_cciidx)
       {
         buyCCI = FastCCI[min_cciidx];
         //bug fix: 当CCI
         is_buy = true;
         is_sell = false;
         if(buy_count + sell_count == 0) is_trigger = true; //      
       }
       else if (max_cciidx < min_cciidx)
       {
         sellCCI = FastCCI[max_cciidx];
         is_buy = false;
         is_sell = true; 
         if(buy_count + sell_count == 0) is_trigger = true; //    
       }
       else
       {
         printf("min cci = max cci");
       }
       return(true);
     }
     else if(max_ccifast >200.00 || min_ccifast < -200.00)
     {
       if(max_ccifast >200.00)
       {
         sellCCI = max_ccifast;
         is_buy = false;
         is_sell = true;
         is_trigger = true;
       }
       else if(min_ccifast < -200.00)
       {
         buyCCI = min_ccifast;
         is_buy = true;
         is_sell = false;
         is_trigger = true;
       }
      return(true);
     }
   }
   else
   {
     return(false);
   }
   return(true);
}


// 保存参数到文件
void Save(string file_name, Params & param)
{
   int file_handle = FileOpen(file_name,FILE_WRITE|FILE_SHARE_WRITE|FILE_CSV,",",CP_UTF8);
   if(file_handle != INVALID_HANDLE)
   {
     FileWrite(file_handle,
        param.is_buy, param.is_sell, param.is_trigger);
   }
   FileClose(file_handle);
   
}

// 读取文件
void Load(string file_name, Params & param)
{
   int file_handle = FileOpen(file_name,FILE_READ|FILE_SHARE_READ|FILE_CSV,",",CP_UTF8);
   if(file_handle != INVALID_HANDLE)
   {
      string data[3];
      int count = 0;
      while(!FileIsEnding(file_handle))
      {
          data[count] = FileReadString(file_handle);
          count++;
      }
      // 把文件数据写入到结构体
      param.is_buy = StringToBool(data[0]);
      param.is_sell = StringToBool(data[1]);
      param.is_trigger = StringToBool(data[2]);
   }
   FileClose(file_handle);
}



bool StringToBool(string s_bool)
{
    if(s_bool == "true")
    {
        return true;
    }
    else if(s_bool == "false")
    {
        return false;
    }
    else
    {
        // Handle other cases if necessary
        return true; // 默认情况下，返回false
    }
}