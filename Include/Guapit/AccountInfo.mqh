
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| 账户相关的函数                                                   |
//+------------------------------------------------------------------+

// 1. 账户信息结构体
struct AccountInfo
{
   int id; // 账户ID
   string name; // 账户姓名
   double balance; // 账户的余额
   double equity; // 账户的净值
   double margin; // 已使用的预付款
   double margin_free; // 未使用的预付款
   double margin_level; // 维持保证金比例线
   double so_so; // 爆仓比例
   int mode; // 账户的类型
   bool is_trade; // 是否允许交易
   bool is_ea; // 是否允许EA交易
};

void getAccountInfo(AccountInfo &account_info)
{
   account_info.id = (int)AccountInfoInteger(ACCOUNT_LOGIN);
   account_info.name = AccountInfoString(ACCOUNT_NAME);
   account_info.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   account_info.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   account_info.margin = AccountInfoDouble(ACCOUNT_MARGIN);
   account_info.margin_free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   account_info.margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   account_info.mode = (int)AccountInfoInteger(ACCOUNT_TRADE_MODE);
   account_info.is_trade = (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
   account_info.is_ea = (bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
}