//+------------------------------------------------------------------+
//|                                                     CATRPattern.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayLong.mqh>
#include "Include\DKStdLib\Common\CDKBarTag.mqh";
#include "Include\DKStdLib\Logger\DKLogger.mqh"
#include "Include\DKStdLib\Drawing\DKChartDraw.mqh"

enum ENUM_TRADE_DIR {
  TRADE_DIR_BUY     = 1, // Только BUY
  TRADE_DIR_SELL    = 2, // Только SELL
  TRADE_DIR_BUYSELL = 3 // BUY + SELL
};


class CATRPattern : public CObject {
protected:
  string                   Prefix;
  string                   Sym;
  int                      Dig;
  ENUM_TIMEFRAMES          TF;
  ENUM_TIMEFRAMES          TFATR;
  int                      Handle;
  DKLogger                 Logger;

public:  
  CDKBarTag                BarBuyInit;
  CDKBarTag                BarBuyFirst;
  CDKBarTag                BarBuyFirstTP;
  CDKBarTag                BarBuyStart;
  CDKBarTag                BarBuyFinish;
  CDKBarTag                BarSellInit;  
  CDKBarTag                BarSellFirst;
  CDKBarTag                BarSellFirstTP;
  CDKBarTag                BarSellStart;
  CDKBarTag                BarSellFinish;
  
  bool                     BuyEnabled;
  bool                     SellEnabled;

  void                     CATRPattern::Init(const string _sym, 
                                             const ENUM_TIMEFRAMES _tf, 
                                             const ENUM_TIMEFRAMES _tf_atr, 
                                             const int _handle, 
                                             const string _prefix);
                                             
  void                     CATRPattern::Find(const datetime _dt);
                                          
  void                     CATRPattern::Draw(const bool _fill,
                                             const uint _width,
                                             const ENUM_LINE_STYLE _style,
                                             const color _color_buy,
                                             const color _color_sell);
};

void CATRPattern::Init(const string _sym, 
                       const ENUM_TIMEFRAMES _tf, 
                       const ENUM_TIMEFRAMES _tf_atr, 
                       const int _handle, 
                       const string _prefix) {
  Prefix = _prefix;
  Sym = _sym;
  TF = _tf;
  TFATR = _tf_atr;
  Handle = _handle;
  
  Dig = 0;
  CSymbolInfo sym_info;
  if (sym_info.Name(Sym)) Dig = sym_info.Digits();
  
  BuyEnabled = true;
  SellEnabled = false;
}

void CATRPattern::Find(const datetime _dt) {
                       
  int atr_init_idx = iBarShift(Sym, TFATR, _dt);
  datetime atr_init_date = iTime(Sym, TFATR, atr_init_idx);
  double open_price = iOpen(Sym, TFATR, atr_init_idx);
  
  int start_idx = iBarShift(Sym, TF, _dt);
  int finish_idx = iBarShift(Sym, TF, atr_init_date);
  int cnt = finish_idx-start_idx+1;
  double highest_price = iHigh(Sym, TF, iHighest(Sym, TF, MODE_HIGH, cnt, start_idx));
  double lowest_price = iLow(Sym, TF, iLowest(Sym, TF, MODE_LOW, cnt, start_idx));

  double atr[];
  if (CopyBuffer(Handle, 0, atr_init_idx, 1, atr) <= 0) return;
  
  double atr_dist = atr[0]; //*_atr_percent/100;
  
  double buy_shift = 0.0;
  double sell_shift = 0.0;
  
  if (lowest_price < open_price) sell_shift = open_price-lowest_price;
  if (highest_price > open_price) buy_shift = highest_price-open_price;
  
  // Sell zone
  if (BarSellInit.GetTime() != atr_init_date) {
    BarSellInit.Init(Sym, TF, atr_init_date);
    BarSellInit.SetValue(NormalizeDouble(open_price + atr_dist, Dig));
    SellEnabled = true;
  }
  BarSellStart.Init(Sym, TF, atr_init_date);
  BarSellStart.SetValue(NormalizeDouble(BarSellInit.GetValue() - sell_shift, Dig));  
  BarSellFinish.Init(Sym, TF, _dt);
  BarSellFinish.SetValue(NormalizeDouble(BarSellStart.GetValue() + atr_dist/10, Dig));
  
  // Buy zone
  if (BarBuyInit.GetTime() != atr_init_date) {
    BarBuyInit.Init(Sym, TF, atr_init_date);
    BarBuyInit.SetValue(NormalizeDouble(open_price - atr_dist, Dig));
    BuyEnabled = true;
  }
  BarBuyStart.Init(Sym, TF, atr_init_date);
  BarBuyStart.SetValue(NormalizeDouble(BarBuyInit.GetValue() + buy_shift, Dig));  
  BarBuyFinish.Init(Sym, TF, _dt);
  BarBuyFinish.SetValue(NormalizeDouble(BarBuyStart.GetValue() - atr_dist/10, Dig));
}

void CATRPattern::Draw(const bool _fill,
                       const uint _width,
                       const ENUM_LINE_STYLE _style,
                       const color _color_buy,
                       const color _color_sell) {          
                       
  RectangleCreate(0,        // ID графика
                  StringFormat("%s|BUY|REC|%s", Prefix, TimeToString(BarBuyInit.GetTime())),  // имя прямоугольника
                  StringFormat("%s|BUY|REC|%s|%d", Prefix, TimeToString(BarBuyInit.GetTime()), BuyEnabled), // описание прямоугольника
                  0,      // номер подокна 
                  BarBuyStart.GetTime(),           // время первой точки
                  BarBuyStart.GetValue(),          // цена первой точки
                  BarBuyFinish.GetTime(),           // время второй точки
                  BarBuyFinish.GetValue(),          // цена второй точки
                  _color_buy,        // цвет прямоугольника
                  _style, // стиль линий прямоугольника
                  _width,           // толщина линий прямоугольника
                  _fill,        // заливка прямоугольника цветом
                  true,        // на заднем плане
                  false,    // выделить для перемещений
                  false,       // скрыт в списке объектов
                  0);         // приоритет на нажатие мышью)
                  
  TextCreate(0,               // ID графика 
             StringFormat("%s|BUY|INIT|%s", Prefix, TimeToString(BarBuyInit.GetTime())), // name
             0,             // номер подокна 
             BarBuyInit.GetTime(),            // время точки привязки
             BarBuyInit.GetValue(),           // цена точки привязки
             "—", //"ê",              // сам текст 
             "Arial", //"Wingdings",             // шрифт 
             10,             // размер шрифта 
             _color_buy,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                // приоритет на нажатие мышью                   

  RectangleCreate(0,        // ID графика
                  StringFormat("%s|SELL|REC|%s", Prefix, TimeToString(BarBuyInit.GetTime())),  // имя прямоугольника
                  StringFormat("%s|SELL|REC|%s|%d", Prefix, TimeToString(BarBuyInit.GetTime()), SellEnabled), // описание прямоугольника
                  0,      // номер подокна 
                  BarSellStart.GetTime(),           // время первой точки
                  BarSellStart.GetValue(),          // цена первой точки
                  BarSellFinish.GetTime(),           // время второй точки
                  BarSellFinish.GetValue(),          // цена второй точки
                  _color_sell,        // цвет прямоугольника
                  _style, // стиль линий прямоугольника
                  _width,           // толщина линий прямоугольника
                  _fill,        // заливка прямоугольника цветом
                  true,        // на заднем плане
                  false,    // выделить для перемещений
                  false,       // скрыт в списке объектов
                  0);         // приоритет на нажатие мышью)
                  
  TextCreate(0,               // ID графика 
             StringFormat("%s|SELL|INIT|%s", Prefix, TimeToString(BarBuyInit.GetTime())), // name
             0,             // номер подокна 
             BarSellInit.GetTime(),            // время точки привязки
             BarSellInit.GetValue(),           // цена точки привязки
             "—", // é",              // сам текст 
             "Arial", //"Wingdings",             // шрифт 
             10,             // размер шрифта 
             _color_sell,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                // приоритет на нажатие мышью 
}