//+------------------------------------------------------------------+
//|                                                          CCI.mq5 |
//|                             Copyright 2000-2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2000-2023, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property description "Commodity Channel Index"
#include <MovingAverages.mqh>
//---
#property indicator_separate_window
#property indicator_buffers       8
#property indicator_plots         2
#property indicator_type1         DRAW_LINE
#property indicator_level1       -100.0
#property indicator_level2        100.0
#property indicator_level1       -200.0
#property indicator_level2        200.0
#property indicator_minimum      -500.00
#property indicator_maximum       500.00
#property indicator_applied_price PRICE_TYPICAL

input int  InpCCIPeriod_Fast=18; // Fast Period
int  InpCCIColor_Fast = clrAqua;
input int  InpCCIPeriod_Slow=54; // Slow Period
int  InpCCIColor_Slow = clrYellow;
//--- indicator fast buffers
double     ExtSPBuffer_Fast[];
double     ExtDBuffer_Fast[];
double     ExtMBuffer_Fast[];
double     ExtCCIBuffer_Fast[];

int        ExtCCIPeriod_Fast;
double     ExtMultiplyer_Fast;

//--- indicator slow buffers
double     ExtSPBuffer_Slow[];
double     ExtDBuffer_Slow[];
double     ExtMBuffer_Slow[];
double     ExtCCIBuffer_Slow[];

int        ExtCCIPeriod_Slow;
double     ExtMultiplyer_Slow;

int OnInit()
  {
//--- check for input value of period
   if(InpCCIPeriod_Fast<=0)
     {
      ExtCCIPeriod_Fast=18;
      PrintFormat("Incorrect value for input variable InpCCIPeriod Fast=%d. Indicator will use value=%d for calculations.",InpCCIPeriod_Fast,ExtCCIPeriod_Fast);
     }
   else
      ExtCCIPeriod_Fast=InpCCIPeriod_Fast;
   ExtMultiplyer_Fast=0.015/ExtCCIPeriod_Fast;
   
   if(InpCCIPeriod_Slow<=0)
     {
      ExtCCIPeriod_Slow=54;
      PrintFormat("Incorrect value for input variable InpCCIPeriod Slow=%d. Indicator will use value=%d for calculations.",InpCCIPeriod_Slow,ExtCCIPeriod_Slow);
     }
   else
      ExtCCIPeriod_Slow=InpCCIPeriod_Slow;  
  
  
   ExtMultiplyer_Fast=0.015/ExtCCIPeriod_Fast;
   ExtMultiplyer_Slow=0.015/ExtCCIPeriod_Slow;
//--- define buffers
   SetIndexBuffer(0,ExtCCIBuffer_Fast);
   SetIndexBuffer(1,ExtCCIBuffer_Slow);
   SetIndexBuffer(2,ExtDBuffer_Fast,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtMBuffer_Fast,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtSPBuffer_Fast,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtDBuffer_Slow,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,ExtMBuffer_Slow,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,ExtSPBuffer_Slow,INDICATOR_CALCULATIONS);   

   string name=StringFormat("CCI FAST(%d) SLOW(%d)",ExtCCIPeriod_Fast, ExtCCIPeriod_Slow);
   IndicatorSetString(INDICATOR_SHORTNAME,name);

   PlotStyle(0,"快速线",DRAW_LINE,STYLE_SOLID,InpCCIColor_Fast,3);
   PlotStyle(1,"慢速线",DRAW_LINE,STYLE_SOLID,InpCCIColor_Slow,3);

   return(INIT_SUCCEEDED);
  }



int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {

   int start=(ExtCCIPeriod_Slow-1)+begin;
   if(rates_total<start) return(0);

//--- calculate position
   int pos = 0;
   pos=prev_calculated-1;
   if(pos<start)
      pos=start;
//--- main cycle
   for(int i=pos; i<rates_total && !IsStopped(); i++)
     {

      ExtSPBuffer_Fast[i]=SimpleMA(i,ExtCCIPeriod_Fast,price);
      //--- calculate D
      double tmp_d=0.0;
      for(int j=0; j<ExtCCIPeriod_Fast; j++)
         tmp_d+=MathAbs(price[i-j]-ExtSPBuffer_Fast[i]);
      ExtDBuffer_Fast[i]=tmp_d*ExtMultiplyer_Fast;
      //--- calculate M
      ExtMBuffer_Fast[i]=price[i]-ExtSPBuffer_Fast[i];
      //--- calculate CCI
      if(ExtDBuffer_Fast[i]!=0.0)
         ExtCCIBuffer_Fast[i]=ExtMBuffer_Fast[i]/ExtDBuffer_Fast[i];
      else
         ExtCCIBuffer_Fast[i]=0.0;
         
         
      ExtSPBuffer_Slow[i]=SimpleMA(i,ExtCCIPeriod_Slow,price);
      //--- calculate D
      double tmp_e=0.0;
      for(int k=0; k<ExtCCIPeriod_Slow; k++)
         tmp_e+=MathAbs(price[i-k]-ExtSPBuffer_Slow[i]);
      ExtDBuffer_Slow[i]=tmp_e*ExtMultiplyer_Slow;
      //--- calculate M
      ExtMBuffer_Slow[i]=price[i]-ExtSPBuffer_Slow[i];
      //--- calculate CCI
      if(ExtDBuffer_Slow[i]!=0.0)
         ExtCCIBuffer_Slow[i]=ExtMBuffer_Slow[i]/ExtDBuffer_Slow[i];
      else
         ExtCCIBuffer_Slow[i]=0.0;
     }
//--- OnCalculate done. Return new prev_calculated.



   return(rates_total);
  }
  
  
void PlotStyle(const int pos,const string label,const ENUM_DRAW_TYPE draw_type, const ENUM_LINE_STYLE line_style,
               const color line_color,const int width)
{
    PlotIndexSetString(pos,PLOT_LABEL,label);
    PlotIndexSetInteger(pos,PLOT_DRAW_TYPE,draw_type);
    PlotIndexSetInteger(pos,PLOT_LINE_STYLE,line_style);
    PlotIndexSetInteger(pos,PLOT_LINE_WIDTH,width);
    PlotIndexSetInteger(pos,PLOT_LINE_COLOR,line_color);
}
