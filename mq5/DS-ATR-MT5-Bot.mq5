//+------------------------------------------------------------------+
//|                                               DS-ATR-MT5-Bot.mq5 |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#property script_show_inputs

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\DKLogger.mqh"
#include "Include\DKStdLib\License\DKLicense.mqh";
#include "Include\DKStdLib\TradingManager\CDKTrade.mqh"

#include "CATRBot.mqh"

input     group                    "1. ОСНОВНЫЕ НАСТРОЙКИ"
input     ENUM_TRADE_DIR           SetTypePos                            = TRADE_DIR_BUYSELL;                   // Type_position: Тип позиции
input     uint                     Max_spread_buy                        = 30;                                  // Max_spread_buy: Максимальный спред для BUY
input     uint                     Count_try_buy                         = 5;                                   // Count_try_buy: Кол-во проверок спреда для BUY
input     uint                     Check_minute                          = 5;                                   // Check_minute: Кол-во минут для новой проверки спреда
input     bool                     Is_comment                            = true;                                // Is_comment: Вкл\выкл комментирование
input     ENUM_TYPE_LOT            Type_lot                              = TYPE_LOT_FIXED;                      // Type_lot: Тип ММ
input     uint                     Min_distance                          = 360;                                 // Min_distance: Минимальное расстояние между уровнями для открытия позиции
input     double                   Lot                                   = 0.01;                                // Lot: Лот
input     double                   Multi                                 = 2.0;                                 // Multi: Мультипликатор лота (мартингейл)
input     uint                     Pair_ratio                            = 7;                                   // Pair_ratio: Коэффициент парности
input     uint                     Min_takeP                             = 10;                                  // Min_takeP: Минимальный тейк профит для срабатывания усреднения
input     uint                     DK_MinGridStepPnt                     = 100;                                 // DK_MinGridStepPnt: Мин. шаг между позициями, пункт (0-откл.)
input     uint                     Slip                                  = 50;                                  // Slip: Проскальзывание
input     ulong                    MagicBuy                              = 202406121;                           // MagicBuy: Магик BUY
input     ulong                    MagicSell                             = 202406122;                           // MagicSell: Магик SELL
input     uint                     Max_pos                               = 10;                                  // Max_pos: Максимальное кол-во сделок в одном направлении
input     group                    "2. РИСК МЕНЕДЖМЕНТ"
input     ENUM_CLOSE_TYPE          Type_close                            = CLOSE_TYPE_FULL_SIDE;                // Type_close: Принудительный стоп лосс
input     double                   Max_risk                              = 270;                                 // Max_risk: Максимальная просадка одной стороны в $
input     group                    "3. ТФ 1"
input     uint                     Percent_take_1                        = 100;                                 // Percent_take_1: Размер ТП относительно расстояния ATR 1, %
input     uint                     Count_atrMTF_tf_1                     = 48;                                  // Count_atrMTF_tf_1: ТФ 1 Кол-во баров для начального расчета ATR
input     ENUM_TIMEFRAME_CUSTOM    Time_frame                            = TIMEFRAME_CUSTOM_D1;                 // Time_frame: ТФ 1 для ATR 
input     bool                     RepeatSignal                          = true;                                // RepeatSignal: Брать ли повторный сигнал
input     group                    "4. ТФ 2"
input     bool                     Is_time_frame_2                       = true;                                // Is_time_frame_2: Вкл\выкл ТФ 2
input     uint                     Percent_take_2                        = 55;                                  // Percent_take_2: Размер ТП относительно расстояния ATR 2, %
input     uint                     Count_atrMTF_tf_2                     = 40;                                  // Count_atrMTF_tf_2: ТФ 2 Кол-во баров для начального расчета ATR
input     ENUM_TIMEFRAME_CUSTOM    Time_frame_2                          = TIMEFRAME_CUSTOM_W1;                 // Time_frame_2: ТФ 2 для ATR 
input     group                    "5. ТФ 3"
input     bool                     Is_time_frame_3                       = true;                                // Is_time_frame_3: Вкл\выкл ТФ 3
input     uint                     Percent_take_3                        = 55;                                  // Percent_take_3: Размер ТП относительно расстояния ATR 3, %
input     uint                     Count_atrMTF_tf_3                     = 6;                                   // Count_atrMTF_tf_3: ТФ 3 Кол-во баров для начального расчета ATR
input     ENUM_TIMEFRAME_CUSTOM    Time_frame_3                          = TIMEFRAME_CUSTOM_W1;                 // Time_frame_3: ТФ 3 для ATR 
input     group                    "6. ГРАФИКА"
input     bool                     Show_visual                           = true;                                // Show_visual: Отображать графику
input     color                    Support_color_1                       = clrMintCream;                        // Support_color_1: Цвет прямоугольника поддержки ТФ 1
input     color                    Resistance_color_1                    = clrPink;                             // Resistance_color_1: Цвет прямоугольника поддержки ТФ 1
input     color                    Support_color_2                       = clrLime;                             // Support_color_2: Цвет прямоугольника поддержки ТФ 2
input     color                    Resistance_color_2                    = clrRed;                              // Resistance_color_2: Цвет прямоугольника поддержки ТФ 2
input     color                    Support_color_3                       = clrDarkGreen;                        // Support_color_3: Цвет прямоугольника поддержки ТФ 3
input     color                    Resistance_color_3                    = clrBrown;                            // Resistance_color_3: Цвет прямоугольника поддержки ТФ 3
input     bool                     Sup_res_fill                          = false;                               // Sup_res_fill: Заливка
input     uint                     Sup_res_width                         = 2;                                   // Sup_res_width: Толщина границ прямоугольника
input     ENUM_LINE_STYLE          Sup_res_style                         = STYLE_SOLID;                         // Sup_res_style: Стиль границ прямоугольника
input     string                   CommentBot                            = "DSATR";                             // CommentBot: Комментарий к позициям

input     group                    "7. ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ"
sinput    LogLevel                 InpLL                                 = LogLevel(INFO);                      // 11.LL: Log Level
          uint                     InpCommentUpdateDelayMs               = 5*1000;                              // Update comment delay

CDKSymbolInfo                      sym;
CATRBot                            bot;

void InitTrade(CDKTrade& _trade, const long _magic, const ulong _slippage) {
  _trade.SetExpertMagicNumber(_magic);
  _trade.SetMarginMode();
  _trade.SetTypeFillingBySymbol(Symbol());
  _trade.SetDeviationInPoints(_slippage);  
  _trade.SetLogger(bot.Logger);
  _trade.LogLevel(LOG_LEVEL_NO);
}

void InitLogger(DKLogger& _logger) {
  _logger.Name = CommentBot;
  _logger.Level = InpLL;
  _logger.Format = "%name%:[%level%] %message%";
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
  MathSrand(GetTickCount());
  
  // Loggers init
  InitLogger(bot.Logger);

  // Проверим режим счета. Нужeн ОБЯЗАТЕЛЬНО ХЕДЖИНГОВЫЙ счет
  CAccountInfo acc;
  if(acc.MarginMode() != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) {
    bot.Logger.Error("Only hedging mode allowed", true);
    return(INIT_FAILED);
  }
  
  if(!sym.Name(Symbol())) {
    bot.Logger.Error(StringFormat("Symbol %s is not available", Symbol()), true);
    return(INIT_FAILED);
  }
  
  if(MagicBuy == MagicSell) {
    bot.Logger.Error("Set different Magic to sell and to buy", true);
    return(INIT_FAILED);
  } 
  
  if (Type_lot == TYPE_LOT_PAIR && Pair_ratio <= 0) {
    bot.Logger.Error("Коэффициент парности должен быть >0", true);
    return(INIT_FAILED);
  } 
  
  bot.Sym = sym;
  bot.TF = Period();
  InitTrade(bot.TradeBuy, MagicBuy, Slip);
  InitTrade(bot.TradeSell, MagicSell, Slip);
  
  bot.SetTypePos = SetTypePos;
  bot.Max_spread_buy = Max_spread_buy;
  bot.Count_try_buy = Count_try_buy;
  bot.Check_minute = Check_minute;
  bot.Is_comment = Is_comment;
  bot.Type_lot = Type_lot;
  bot.Min_distance = Min_distance;
  bot.Lot = Lot;
  bot.Multi = Multi;
  bot.Pair_ratio = Pair_ratio;
  bot.Min_takeP = Min_takeP;
  bot.DK_MinGridStepPnt = DK_MinGridStepPnt;
  bot.Slip = Slip;
  bot.MagicBuy = MagicBuy;
  bot.MagicSell = MagicSell;
  bot.Max_pos = Max_pos;
  bot.Type_close = Type_close;
  bot.Max_risk = Max_risk;
  bot.Percent_take_1 = Percent_take_1;
  bot.Count_atrMTF_tf_1 = Count_atrMTF_tf_1;
  bot.Time_frame = Time_frame;
  bot.RepeatSignal = RepeatSignal;
  bot.Is_time_frame_2 = Is_time_frame_2;
  bot.Percent_take_2 = Percent_take_2;
  bot.Count_atrMTF_tf_2 = Count_atrMTF_tf_2;
  bot.Time_frame_2 = Time_frame_2;
  bot.Is_time_frame_3 = Is_time_frame_3;
  bot.Percent_take_3 = Percent_take_3;
  bot.Count_atrMTF_tf_3 = Count_atrMTF_tf_3;
  bot.Time_frame_3 = Time_frame_3;
  bot.Show_visual = Show_visual;
  bot.Support_color_1 = Support_color_1;
  bot.Resistance_color_1 = Resistance_color_1;
  bot.Support_color_2 = Support_color_2;
  bot.Resistance_color_2 = Resistance_color_2;
  bot.Support_color_3 = Support_color_3;
  bot.Resistance_color_3 = Resistance_color_3;
  bot.Sup_res_fill = Sup_res_fill;
  bot.Sup_res_width = Sup_res_width;
  bot.Sup_res_style = Sup_res_style;
  bot.CommentBot = CommentBot;  
 
  bot.Init();

  EventSetMillisecondTimer(InpCommentUpdateDelayMs);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
//--- destroy timer
   EventKillTimer();
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()  {
  bot.OnTick();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()  {
  bot.OnTimer();
}

//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()  {
  bot.OnTrade();
}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {

   
  }

