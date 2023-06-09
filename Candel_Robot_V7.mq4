//+------------------------------------------------------------------+
//|                                                 Candel Robot.mq4 |
//|                                                        Pashka!   |
//|                                                              ... |
//+------------------------------------------------------------------+
#property copyright "Pol"
#property link      "..."
#property version   "7.00"
#property strict
//--- input parameters
input int TakeProfit       = 0;              //Тейк Профит в пунктах
input int TakePercent      = 50;             //Тейк Профит в % от Стопа
input double StopL         = 4;              //Стоп Лосс (% от текущей цены)
input int TP               = 50;             //Отклонение Профита для БУ
input int Mult1            = 2;              //Мультик для 50%
input int Mult2            = 6;              //Мультик для 75%
input int Mult3            = 18;             //Мультик для 87,5%
input double Lot           = 0.01;           //Лотность
input int Magic            = 88;             //Магик
input int xdis             = 300;            //Button Distanse X
input bool avtotrade = false;                //Автоторговля
input bool currentP = true;                  //Использовать % от текущей цены


int buysell                            = 0;  //Параметр для тестирования
double   point                         = MarketInfo(Symbol(),MODE_POINT);
bool     New_Bar                       = false;
bool     flagSell1                     = false;
bool     flagSell2                     = false;
bool     flagBuy1                      = false;
bool     flagBuy2                      = false;
bool     stop                          = false; 
bool     stop2                         = false; 
bool     stop3                         = false; 
// Глобальные значения котировок 
double   StpValue;      // Расстояние до Стопа
double   TakeP;         // Расстояние до Тейка
double   StpValue25p;   // 25% от Открытия или первый БУ
double   StpValue50p;   // 50% от Открытия или второй БУ
double   StpValue75p;   // 75% от Открытия или третий БУ
double   StpValue85p;   // 85% от Открытия или третий БУ

//==============================
int TicketSell = 0;
int TicketBuy = 0;
int TicketLimitS1 = 0;
int TicketLimitS2 = 0;
int TicketLimitS3 = 0;
int TicketLimitB1 = 0;
int TicketLimitB2 = 0;
int TicketLimitB3 = 0;

datetime data_close=D'02.01.2024';                    //в эту дату уже работать не будет
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
        // Первоначальное создание кнопки при запуске
   ObjectCreate(0,"Button",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"Button",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,"Button",OBJPROP_XDISTANCE,xdis);
   ObjectSetInteger(0,"Button",OBJPROP_YDISTANCE,5);
   ObjectSetInteger(0,"Button",OBJPROP_XSIZE,60);
   ObjectSetInteger(0,"Button",OBJPROP_YSIZE,20);
   ObjectSetInteger(0,"Button",OBJPROP_BGCOLOR,clrGreen);
   ObjectSetString(0,"Button",OBJPROP_TEXT,"Buy");
   ObjectSetInteger(0,"Button",OBJPROP_COLOR,clrWhite);
      //----------------------------------------------------------------
   ObjectCreate(0,"Button1",OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,"Button1",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,"Button1",OBJPROP_XDISTANCE,xdis-70);
   ObjectSetInteger(0,"Button1",OBJPROP_YDISTANCE,5);
   ObjectSetInteger(0,"Button1",OBJPROP_XSIZE,60);
   ObjectSetInteger(0,"Button1",OBJPROP_YSIZE,20);
   ObjectSetInteger(0,"Button1",OBJPROP_BGCOLOR,clrMaroon);
   ObjectSetString(0,"Button1",OBJPROP_TEXT,"Sell");
   ObjectSetInteger(0,"Button1",OBJPROP_COLOR,clrWhite);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  ObjectsDeleteAll(ChartID(), "Button");
  ObjectsDeleteAll(ChartID(), "Button1");
  Comment("");
//---  
  }
//+------------------------------------------------------------------+
//| ================ Expert tick function ================           |
//+------------------------------------------------------------------+
void OnTick()
  {
   string torg;
   New_Bar=false;
   if(TimeCurrent()<=data_close)// Проверка на срок годности индикатора :))
     {
      New_Bar=true;
     }
     else
     {
      Comment(" === Срок действия индикатора истек! === ");
     }
   if(New_Bar)
     {
     Autotrade();
     Breakeven_sell();
     Breakeven_buy();
     }
   if (buysell == 1) torg = ">> BUY <<";
   if (buysell == 2) torg = ">> SELL <<";
   if (buysell == 0) torg = ">> BUY / SELL <<";
   Comment("Стоп >> ", StpValue, "\n","Тейк >> ", TakeP, "\n", torg);//, "\n", stop);    
  }
//+------------------------------------------------------------------+
void ButtonClicks()
{

   if(New_Bar)
     {
   if(ObjectGetInteger(0,"Button",OBJPROP_STATE,0)!=false)
        {
         Buywork();
         buysell = 1;
         ObjectSetInteger(0,"Button",OBJPROP_STATE,0);
        }
   if(ObjectGetInteger(0,"Button1",OBJPROP_STATE,0)!=false)
        {
         Sellwork();
         buysell = 2;
         ObjectSetInteger(0,"Button1",OBJPROP_STATE,0);
        }
     }  
}

void OnChartEvent(const int id, //don't change anything here
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   ButtonClicks();
}
//---------------------------------------------------------------------------
void Autotrade()
{
if (avtotrade && buysell == 0) buysell = 2; 
int count = 0; // Количество открытых ордеров с Magic номером

   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderType() == OP_BUY || OrderType() == OP_SELL) count++;
   }
   
   if (count == 0) 
      {      
         if (avtotrade && buysell == 2)
            {
             //Print(">>>>>>> S T O P        F A L S E <<<<<<<<<<");
             Sellwork();
            }
         if (avtotrade && buysell == 1)
            {
             //Print(">>>>>>> S T O P        F A L S E <<<<<<<<<<");
             Buywork();
            }
      }   
}

//+=== Основные расчёты по формуле  ===================================================================================+
void Weekend()
{

double   HighWeek;
double   HighMonth;
double   High3Month;
double   High6Month;
double   HighM;

double   LowWeek;
double   LowMonth;
double   Low3Month;
double   Low6Month;
double   LowM;

double   ValueWeek;
double   ValueMonth;
double   Value3Month;
double   Value6Month;
double   Value5;


HighWeek  = iHigh(_Symbol, PERIOD_W1, 1);
LowWeek   = iLow(_Symbol, PERIOD_W1, 1);
ValueWeek = HighWeek - LowWeek;

HighMonth  = iHigh(_Symbol, PERIOD_MN1, 1);
LowMonth   = iLow(_Symbol, PERIOD_MN1, 1);
ValueMonth = HighMonth/LowMonth;

High3Month =0;
Low3Month  =9999999999;
for (int i=1; i<4; i++)
   { 
      HighM  = iHigh(_Symbol, PERIOD_MN1,i);
      LowM   = iLow(_Symbol, PERIOD_MN1, i);
      if (HighM > High3Month) High3Month = HighM;
      if (LowM < Low3Month) Low3Month = LowM;
   }
Value3Month = High3Month/Low3Month;

High6Month =0;
Low6Month  =9999999999;
for (int i=1; i<7; i++)
   { 
      HighM  = iHigh(_Symbol, PERIOD_MN1,i);
      LowM   = iLow(_Symbol, PERIOD_MN1, i);
      if (HighM > High6Month) High6Month = HighM;
      if (LowM < Low6Month) Low6Month = LowM;
   }
Value6Month = High6Month/Low6Month;

Value5      = ValueMonth*Value3Month*Value6Month;
//---------
if (currentP)
   {
      double currentPrice = MarketInfo(Symbol(), MODE_BID);
      StpValue = NormalizeDouble((currentPrice*StopL/100)/point,0);
   }else
      {
         StpValue    = ValueWeek*Value5;
         StpValue    = NormalizeDouble(StpValue/point,0);
      }
if (TakeProfit == 0)
   { 
      TakeP = TakePercent*StpValue/100;    
   }else
      {
      TakeP = TakeProfit;
      }
//---------
StpValue25p = StpValue*25/100;
StpValue50p = StpValue*50/100;
StpValue75p = StpValue*75/100;  
StpValue85p = StpValue*87/100;  

Print("Значение 1 == " + DoubleToString(ValueWeek));
Print("Значение 2 == " + DoubleToString(ValueMonth));
Print("Значение 3 == " + DoubleToString(Value3Month));
Print("Значение 4 == " + DoubleToString(Value6Month));
Print("Значение 5 == " + DoubleToString(Value5));
Print("=================================");
Print("Расстояние до Тейка     == " + DoubleToString(TakeP));
Print("Расстояние до стопа     == " + DoubleToString(StpValue));
Print("Расстояние до стопа 25% == " + DoubleToString(StpValue25p));
Print("Расстояние до стопа 50% == " + DoubleToString(StpValue50p));
Print("Расстояние до стопа 75% == " + DoubleToString(StpValue75p));
Print("=================================");
}

//=====================Обработка всх SELL ордеров ==========================
void Sellwork()
{
flagSell1 = false;
flagSell2 = false;
stop  = false;
stop2 = false;
stop3 = false;
int count = 0; // Количество открытых ордеров с Magic номером

   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderType() == OP_BUY || OrderType() == OP_SELL) count++;
   }
   if (count == 0) 
      {
      for (int i = OrdersTotal()-1; i >= 0; i--)
         {
             if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
             {
                 if ((OrderType() == OP_BUYLIMIT  || OrderType() == OP_SELLLIMIT) && OrderMagicNumber() == Magic)
                 {
                     if (OrderDelete(OrderTicket()))
                     {
                         Print("Удален отложенный ордер #", OrderTicket());
                     }
                     else
                     {
                         Print("Ошибка при удалении отложенного ордера #", OrderTicket(), ": ", GetLastError());
                     }
                 }
             }
         }
      Weekend();
      Opensell();
      }
}

//=====================Обработка всх BUY ордеров ==========================
void Buywork()
{
flagBuy1 = false;
flagBuy2 = false;
stop  = false;
stop2 = false;
stop3 = false;
int count = 0; // Количество открытых ордеров с Magic номером

   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderMagicNumber() != Magic) continue;
      if (OrderType() == OP_BUY || OrderType() == OP_SELL) count++;
   }
   
   if (count == 0) 
      {
      for (int i = OrdersTotal()-1; i >= 0; i--)
         {
             if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
             {
                 if ((OrderType() == OP_BUYLIMIT  || OrderType() == OP_SELLLIMIT) && OrderMagicNumber() == Magic)
                 {
                     if (OrderDelete(OrderTicket()))
                     {
                         Print("Удален отложенный ордер #", OrderTicket());
                     }
                     else
                     {
                         Print("Ошибка при удалении отложенного ордера #", OrderTicket(), ": ", GetLastError());
                     }
                 }
             }
         }
      Weekend();
      Openbuy();
      }
}
//===================== Безубыток для  SELL =========================
void Breakeven_sell()
{
   double currentPrice = MarketInfo(Symbol(), MODE_BID);
   //-----------------------------------------------------------------------------
   bool orderSelected = OrderSelect(TicketSell, SELECT_BY_TICKET); // Первый БУ
   double openPrice = OrderOpenPrice();
   double priceDiff = currentPrice - openPrice;
    
   if (orderSelected && OrderCloseTime() == 0)
   {
      if ((priceDiff/point) >= StpValue50p && (priceDiff/point) < StpValue75p && flagSell1 == false && stop == false)
      {
         double newStopLoss = openPrice + TP * point;
         bool orderModified = OrderModify(TicketSell, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Green);
         stop = true;
         if (!orderModified)
         {
            string error = get_Error(GetLastError());
            Print("OrderModify error: ", error);
         }
      }
      if (currentPrice <= (NormalizeDouble(openPrice-(TakeP/2)*_Point,_Digits)) && flagSell1 == false && stop == false)
      {
         buysell = 1;
         double newStopLoss = openPrice - ((TakeP/5) * point);
         bool orderModified = OrderModify(TicketSell, 0, NormalizeDouble(newStopLoss,_Digits), OrderTakeProfit(), 0, Indigo);
         stop = true;
         if (!orderModified)
         {
            string error = get_Error(GetLastError());
            Print("OrderModify error: ", error);
         }
      }
   }
   //-----------------------------------------------------------------------------
   bool orderSelected1 = OrderSelect(TicketLimitS1, SELECT_BY_TICKET); // Второй БУ
   if (orderSelected1 && OrderCloseTime() == 0)
   {
      if ((priceDiff/point) >= StpValue75p && (priceDiff/point) < StpValue85p && flagSell2 == false && stop2 == false)
      {
         double newStopLoss = openPrice + ((StpValue50p-TP) * point );
         buysell = 2;
         flagSell1 = true;
         stop2 = true;
         bool orderModified = OrderModify(TicketSell, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Green);
         bool orderModified1 = OrderModify(TicketLimitS1, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Green);
         if (!orderModified || !orderModified1)
         {
            string error = get_Error(GetLastError());
            Print("OrderModify error: ", error);
         }
      }
   }
   //-----------------------------------------------------------------------------
   bool orderSelected2 = OrderSelect(TicketLimitS2, SELECT_BY_TICKET); // Третий БУ
   if (orderSelected2 && OrderCloseTime() == 0)
   {
      if ((priceDiff/point) >= StpValue85p && stop3 == false)
      {
         double newStopLoss = openPrice + ((StpValue75p-TP) * point);
         flagSell2 = true;
         stop3 = true;
         bool orderModified = OrderModify(TicketSell, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Green);
         bool orderModified1 = OrderModify(TicketLimitS1, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Green);
         bool orderModified2 = OrderModify(TicketLimitS2, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Green);
         if (!orderModified || !orderModified1)
         {
            string error = get_Error(GetLastError());
            Print("OrderModify error: ", error);
         }
      }
   }
}

//===================== Безубыток для  BUY  =========================
void Breakeven_buy()
{
   double currentPrice = MarketInfo(Symbol(), MODE_BID);
   //-----------------------------------------------------------------------------
   bool orderSelected = OrderSelect(TicketBuy, SELECT_BY_TICKET); // Первый БУ 
   double openPrice = OrderOpenPrice();
   double priceDiff = openPrice - currentPrice; 
   
   if (orderSelected && OrderCloseTime() == 0)
   {
      if ((priceDiff/point) >= StpValue50p && (priceDiff/point) < StpValue75p && flagBuy1 == false && stop == false)
      {
         double newStopLoss = openPrice - TP * point;
         bool orderModified = OrderModify(TicketBuy, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Indigo);
         stop = true;
         if (!orderModified)
         {
            string error = get_Error(GetLastError());
            Print("OrderModify error: ", error);
         }
      }
      if (currentPrice >= (NormalizeDouble(openPrice+(TakeP/2)*_Point,_Digits)) && flagBuy1 == false && stop == false)
      {
         buysell = 2;
         double newStopLoss = openPrice + ((TakeP/5) * point);
         bool orderModified = OrderModify(TicketBuy, 8, NormalizeDouble(newStopLoss,_Digits), OrderTakeProfit(), 0, Indigo);
         stop = true;
         if (!orderModified)
         {
            string error = get_Error(GetLastError());
            Print("OrderModify error: ", error);
         }
      }
   }
   //-----------------------------------------------------------------------------
   bool orderSelected1 = OrderSelect(TicketLimitB1, SELECT_BY_TICKET); // Второй БУ
   if (orderSelected1 && OrderCloseTime() == 0)
   {      
      if ((priceDiff/point) >= StpValue75p && (priceDiff/point) < StpValue85p && flagBuy2 == false && stop2 == false)
      {
         double newStopLoss = openPrice - ((StpValue50p-TP) * point );
         buysell = 1;
         flagBuy1 = true;
         stop2 = true;
         bool orderModified = OrderModify(TicketBuy, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Indigo);
         bool orderModified1 = OrderModify(TicketLimitB1, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Indigo);
         if (!orderModified || !orderModified1)
         {
            string error = get_Error(GetLastError());
            Print("OrderModify error: ", error);
         }
      }
   }
   //-----------------------------------------------------------------------------
   bool orderSelected2 = OrderSelect(TicketLimitB2, SELECT_BY_TICKET); // Третий БУ
   if (orderSelected2 && OrderCloseTime() == 0)
   {   
      if ((priceDiff/point) >= StpValue85p && stop3 == false)
      {
         double newStopLoss = openPrice - ((StpValue75p-TP) * point);
         flagBuy2 = true;
         stop3 = true;
         bool orderModified = OrderModify(TicketBuy, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Indigo);
         bool orderModified1 = OrderModify(TicketLimitB1, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Indigo);
         bool orderModified2 = OrderModify(TicketLimitB2, 8, OrderStopLoss(), NormalizeDouble(newStopLoss,_Digits), 0, Indigo);
         if (!orderModified || !orderModified1)
         {
            string error = get_Error(GetLastError());
            Print("OrderModify error: ", error);
         }
      }
   }
   
}

//==========================================================================
void Opensell()
{
double Lot1 = Lot*Mult1;
double Lot2 = Lot*Mult2;
double Lot3 = Lot*Mult3;
double Take25 = StpValue25p-TP;
double Take50 = StpValue50p-TP;
double Take75 = StpValue75p-TP;

if(StpValue != 0)//Проверка для SELL
      {
      if ((TicketSell = OrderSend(_Symbol,OP_SELL,Lot,Bid,50,NormalizeDouble(Bid+StpValue*_Point,_Digits),NormalizeDouble(Bid-TakeP*_Point,_Digits),"Open_SELL",Magic,0,Red)) > -1)
       {
         Print(" Открываем SELL # " + IntegerToString (TicketSell));
       }else
         {
            string error = get_Error(GetLastError());
            Print(error);
         }
      if ((TicketLimitS1 = OrderSend(_Symbol,OP_SELLLIMIT,Lot1,NormalizeDouble(Bid+StpValue*0.50*_Point,_Digits),50,NormalizeDouble(Bid+StpValue*_Point,_Digits),NormalizeDouble(Bid+TP*_Point,_Digits),"Open_SELLLIMIT",Magic,0,Red)) > -1)
       {
         Print("Ставим SELL-LIMIT 50% # " + IntegerToString (TicketLimitS1));
       }else
         {
            string error = get_Error(GetLastError());
            Print(error);
         }
      if ((TicketLimitS2 = OrderSend(_Symbol,OP_SELLLIMIT,Lot2,NormalizeDouble(Bid+StpValue*0.75*_Point,_Digits),50,NormalizeDouble(Bid+StpValue*_Point,_Digits),NormalizeDouble(Bid+Take50*_Point,_Digits),"Open_SELLLIMIT",Magic,0,Red)) > -1)
       {
         Print("Ставим SELL-LIMIT 75% # " + IntegerToString (TicketLimitS2));
       }else
         {
            string error = get_Error(GetLastError());
            Print(error);
         }
      if ((TicketLimitS3 = OrderSend(_Symbol,OP_SELLLIMIT,Lot3,NormalizeDouble(Bid+StpValue*0.875*_Point,_Digits),50,NormalizeDouble(Bid+StpValue*_Point,_Digits),NormalizeDouble(Bid+Take75*_Point,_Digits),"Open_SELLLIMIT",Magic,0,Red)) > -1)
       {
         Print("Ставим SELL-LIMIT 87.5% # " + IntegerToString (TicketLimitS3));
         Print("=================================");
       }else
         {
            string error = get_Error(GetLastError());
            Print(error);
         }        
      }
}

void Openbuy()/////////////////=============== BUY =================///////////////////////////////////////
{
double Lot1 = Lot*Mult1;
double Lot2 = Lot*Mult2;
double Lot3 = Lot*Mult3;
double Take25 = StpValue25p-TP;
double Take50 = StpValue50p-TP;
double Take75 = StpValue75p-TP;

if(StpValue != 0)//Проверка для BUY
      {
      if ((TicketBuy = OrderSend(_Symbol,OP_BUY,Lot,Ask,50,NormalizeDouble(Ask-StpValue*_Point,_Digits),NormalizeDouble(Ask+TakeP*_Point,_Digits),"Open_Buy",Magic,0,Blue)) > -1)
       {
       Print(" Открываем BUY # " + IntegerToString (TicketBuy));
       }else
         {
         string error = get_Error(GetLastError());
         Print(error);
         }
      if ((TicketLimitB1 = OrderSend(_Symbol,OP_BUYLIMIT,Lot1,NormalizeDouble(Ask-StpValue*0.50*_Point,_Digits),50,NormalizeDouble(Ask-StpValue*_Point,_Digits),NormalizeDouble(Ask-TP*_Point,_Digits),"Open_BUYLIMIT",Magic,0,Blue)) > -1)
       {
         Print("Ставим BUY-LIMIT 50% # " + IntegerToString (TicketLimitB1));
       }else
         {
            string error = get_Error(GetLastError());
            Print(error);
         }
      if ((TicketLimitB2 = OrderSend(_Symbol,OP_BUYLIMIT,Lot2,NormalizeDouble(Ask-StpValue*0.75*_Point,_Digits),50,NormalizeDouble(Ask-StpValue*_Point,_Digits),NormalizeDouble(Ask-Take50*_Point,_Digits),"Open_BUYLIMIT",Magic,0,Blue)) > -1)
       {
         Print("Ставим BUY-LIMIT 75% # " + IntegerToString (TicketLimitB2));
       }else
         {
            string error = get_Error(GetLastError());
            Print(error);
         }
      if ((TicketLimitB3 = OrderSend(_Symbol,OP_BUYLIMIT,Lot3,NormalizeDouble(Ask-StpValue*0.875*_Point,_Digits),50,NormalizeDouble(Ask-StpValue*_Point,_Digits),NormalizeDouble(Ask-Take75*_Point,_Digits),"Open_BUYLIMIT",Magic,0,Blue)) > -1)
       {
         Print("Ставим BUY-LIMIT 87.5% # " + IntegerToString (TicketLimitB3));
         Print("=================================");
       }else
         {
            string error = get_Error(GetLastError());
            Print(error);
         }   
      }
}


 //--- Обработчик ошибок ---
string get_Error(int error_code)
{
string error_string = "";

switch (error_code)
   {
   case 0:error_string="Нет ошибки";break;
   case 1:error_string="Нет ошибки, но результат не известен";break;
   case 2:error_string="Общая ошибка";break;
   case 3:error_string="Неправильные параметры";break;
   case 4:error_string="Торговый серсер занят";break;
   case 5:error_string="Старая версия терминала";break;
   case 6:error_string="Нет связи с сервером";break;
   case 7:error_string="Недостаточно прав";break;
   case 8:error_string="Слишком частые запросы";break;
   case 9:error_string="Операция, нарушающая функции сервера";break;
   case 64:error_string="Счёт заблокирован";break;
   case 65:error_string="Неправильный номер счёта";break;
   case 128:error_string="Истёк срок ожидания совершения сделки";break;
   case 129:error_string="Неправильная Цена";break;
   case 130:error_string="Неправильный Стоп";break;
   case 131:error_string="Неправильные Объёмы";break;
   case 132:error_string="Рынок закрыт";break;
   case 133:error_string="Торговля запрещена";break;
   case 134:error_string="Недостаточно денег";break;
   case 135:error_string="Цена изменилась";break;
   case 136:error_string="Нет цен";break;
   case 137:error_string="Брокер занят";break;
   case 138:error_string="Новые цены";break;
   case 139:error_string="Ордер заблокирован и уже обрабатывается";break;
   case 140:error_string="Разрешена только покупка";break;
   case 141:error_string="Слишком много запросов";break;
   case 145:error_string="Модификация ордера запрещена, так как ордер слишком близко к рынку";break;
   case 146:error_string="Подсистема торговли занята";break;
   case 147:error_string="Использование даты истечения ордера запрещено брокером";break;
   case 148:error_string="Количество открытых и отложенных ордеров достигло предела";break;
   }

return(error_string);
}