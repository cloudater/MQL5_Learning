#include <Guapit/Trade.mqh>

input int init_magic=15291406; //Magic Number

enum OrderType{
  BuyType, // Buy方向 0
  SellType // Sell方向 1
};

// 全局变量配置
bool is_buy = false;
int buy_count = 0;
string buy_before;
double buyCCI=0.0;

bool is_sell = false;
int sell_count = 0;
string sell_before;
double sellCCI=0.0;
string ea_comment = "";

int ATRHandle;
double iATRBuffer[]; //ATR数组

int ea_sl = 0;
int ea_tp = 0;

int OnInit()
  {

   EventSetTimer(60);
   ATRHandle=iATR(_Symbol,PERIOD_CURRENT,108);
   if(ATRHandle==INVALID_HANDLE) 
   { 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d", 
                  "iATR", 
                  EnumToString(PERIOD_CURRENT), 
                  GetLastError()); 
      return false;    
   }
   CopyBuffer(ATRHandle,0,0,10, iATRBuffer);
   ArraySetAsSeries(iATRBuffer,true);
   ea_sl=iValuetoPoint(iATRBuffer[0]*6); //ATR当前值的6倍，设置止赢，止损
   ea_tp=ea_sl;
   SellAdd(_Symbol,0.01,ea_sl,ea_tp,5,"MakeUp Add",init_magic);

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   EventKillTimer();
   //--- 获得EA卸载的原因
   Print(__FUNCTION__," EA已经卸载, 发生卸载的原因代码: ",reason); 
   //--- 获得EA重新初始化原因注解, 也可以使用常量函数: _UninitReason
   Print(__FUNCTION__," 卸载原因说明: ",getUninitReasonText(UninitializeReason()));   
  }

void OnTick()
  {

  }

void OnTimer()
  {
      if(PositionClose2(_Symbol, 12, 5, init_magic)) sell_count = 0; //平空       
      ea_comment = "下单平仓测试";
      ea_sl=iValuetoPoint(iATRBuffer[0]*6); //ATR当前值的6倍，设置止赢，止损
      ea_tp=ea_sl;    
      if(BuyAdd(_Symbol,0.01,ea_sl,ea_tp,5,"MakeUp Add",init_magic)) //开多
      {
        is_sell = true;
        is_buy = false;      
      }
  }

int iValuetoPoint(const double f_value) //价格变成点数
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pointValue = MathAbs(f_value)/point;
   int rt_point = MathCeil(MathAbs(pointValue));
   return rt_point;
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
