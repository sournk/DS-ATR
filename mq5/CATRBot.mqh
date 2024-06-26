//+------------------------------------------------------------------+
//|                                                 CATRBot.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+

#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayLong.mqh>

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\DKLogger.mqh"
#include "Include\DKStdLib\TradingManager\CDKPositionInfo.mqh"
#include "Include\DKStdLib\TradingManager\CDKTrade.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLBE.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLStep.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLPriceChannel.mqh"
#include "Include\DKStdLib\TradingManager\CDKTSLStepInd.mqh"
#include "Include\DKStdLib\NewBarDetector\DKNewBarDetector.mqh"

#include "CDKGridATR.mqh"

enum ENUM_CLOSE_TYPE {
  CLOSE_TYPE_FULL_SIDE    = 0, // Закрытие позиции по одной стороне
  CLOSE_TYPE_MAX_LOSS     = 1  // Закрытие самого большого (ориг. убыточного)
};

enum ENUM_TIMEFRAME_CUSTOM {
  TIMEFRAME_CUSTOM_CURRENT = 0,        // Current
  TIMEFRAME_CUSTOM_M1      = 1,        // M1
  TIMEFRAME_CUSTOM_M5      = 5,        // M5
  TIMEFRAME_CUSTOM_M15     = 15,       // M15
  TIMEFRAME_CUSTOM_M30     = 30,       // M30
  TIMEFRAME_CUSTOM_H1      = 60,       // H1
  TIMEFRAME_CUSTOM_H4      = 4*60,     // H4
  TIMEFRAME_CUSTOM_D1      = 24*60,    // D1
  TIMEFRAME_CUSTOM_W1      = 24*60*7,  // W1
  TIMEFRAME_CUSTOM_MN1     = 24*60*30  // MN1
};

ENUM_TIMEFRAMES EnumTimeframeCustomToDefault(const ENUM_TIMEFRAME_CUSTOM _tf_custom) {
  if (_tf_custom == TIMEFRAME_CUSTOM_CURRENT)  return PERIOD_CURRENT;
  if (_tf_custom == TIMEFRAME_CUSTOM_M1)   return PERIOD_M1;
  if (_tf_custom == TIMEFRAME_CUSTOM_M5)   return PERIOD_M5;
  if (_tf_custom == TIMEFRAME_CUSTOM_M15)  return PERIOD_M15;
  if (_tf_custom == TIMEFRAME_CUSTOM_M30)  return PERIOD_M30;
  if (_tf_custom == TIMEFRAME_CUSTOM_H1)   return PERIOD_H1;
  if (_tf_custom == TIMEFRAME_CUSTOM_H4)   return PERIOD_H4;
  if (_tf_custom == TIMEFRAME_CUSTOM_D1)   return PERIOD_D1;
  if (_tf_custom == TIMEFRAME_CUSTOM_W1)   return PERIOD_W1;
  if (_tf_custom == TIMEFRAME_CUSTOM_MN1)  return PERIOD_MN1;
  
  return PERIOD_M5;
}

class CATRBot {
protected:
  DKNewBarDetector         NewBarDetector;
  CArrayLong               PosList;
  
  CDKGridATR               GridBuy;
  CDKGridATR               GridSell;
public:
  bool                     IsShowCommentActive;

  CDKSymbolInfo            Sym;
  ENUM_TIMEFRAMES          TF;
  DKLogger                 Logger;
  CDKTrade                 TradeBuy;
  CDKTrade                 TradeSell;
  
  int                      ATR1Handle;
  int                      ATR2Handle;
  int                      ATR3Handle;
  
  ENUM_TRADE_DIR           SetTypePos;
  uint                     Max_spread_buy;
  uint                     Count_try_buy;
  uint                     Check_minute;
  bool                     Is_comment;
  ENUM_TYPE_LOT            Type_lot;
  uint                     Min_distance;
  double                   Lot;
  double                   Multi;
  uint                     Pair_ratio;
  uint                     Min_takeP;
  uint                     DK_MinGridStepPnt;
  uint                     Slip;
  ulong                    MagicBuy;
  ulong                    MagicSell;
  uint                     Max_pos;
  ENUM_CLOSE_TYPE          Type_close;
  double                   Max_risk;
  uint                     Percent_take_1;
  uint                     Count_atrMTF_tf_1;
  ENUM_TIMEFRAME_CUSTOM    Time_frame;
  bool                     RepeatSignal;
  bool                     Is_time_frame_2;
  uint                     Percent_take_2;
  uint                     Count_atrMTF_tf_2;
  ENUM_TIMEFRAME_CUSTOM    Time_frame_2;
  bool                     Is_time_frame_3;
  uint                     Percent_take_3;
  uint                     Count_atrMTF_tf_3;
  ENUM_TIMEFRAME_CUSTOM    Time_frame_3;
  bool                     Show_visual;
  color                    Support_color_1;
  color                    Resistance_color_1;
  color                    Support_color_2;
  color                    Resistance_color_2;
  color                    Support_color_3;
  color                    Resistance_color_3;
  bool                     Sup_res_fill;
  uint                     Sup_res_width;
  ENUM_LINE_STYLE          Sup_res_style;
  string                   CommentBot;
  
  CArrayObj                PatternList; 

  void                     CATRBot::ShowComment();
  
  CATRPattern*             CATRBot::CreatePattern(const ENUM_TIMEFRAMES _tf, const int _handle);
  void                     CATRBot::UpdatePatterns();
  void                     CATRBot::Draw();
  
  void                     CATRBot::Init();  
  
  int                      CATRBot::GetDirSign(const ENUM_TRADE_DIR _dir) { return (_dir == TRADE_DIR_BUY) ? +1 : -1; }
  ENUM_TRADE_DIR           CATRBot::GetOppositeDir(const ENUM_TRADE_DIR _dir) { return (_dir == TRADE_DIR_BUY) ? TRADE_DIR_SELL : TRADE_DIR_BUY; }
  
  // TP
  double                   CATRBot::GetTPLevel(CDKPositionInfo& _pos);
  double                   CATRBot::GetTPFromZones(CDKPositionInfo& _pos);
  double                   CATRBot::GetTPFromZoneShift(CDKPositionInfo& _pos);
  double                   CATRBot::GetTPDistRatio(const int _zone_idx);
  double                   CATRBot::GetTP(CDKPositionInfo& _pos);
  void                     CATRBot::UpdateTP();  
  
  color                    CATRBot::GetColor(const int _zone_idx, const ENUM_POSITION_TYPE _dir);
  
  // Get all market poses
  void                     CATRBot::GetAllPos();
  
  void                     CATRBot::CheckAndRunHardSL(CDKGridATR& _grid);
 
  // Event Handlers
  void                     CATRBot::OnTick(void);
  void                     CATRBot::OnTrade(void);
  void                     CATRBot::OnTimer(void);
  
  void                     CATRBot::CATRBot(void);
  void                     CATRBot::~CATRBot(void);
};

//+------------------------------------------------------------------+
//| Update current grid status
//+------------------------------------------------------------------+
void CATRBot::ShowComment() {
  if (!IsShowCommentActive) return;

  DKGridState state_buy = GridBuy.GetState();
  DKGridState state_sell = GridSell.GetState();

  string comment = StringFormat("%s\n" +
                                
                                "\nBUY:\n"+
                                "Позиций: %d/%d\n"+
                                "ТФ: %s\n"+
                                "Объем: %f\n"+
                                "Прибыль: %f\n"+
                                "Б/У: %f\n"+
                                
                                "\nSELL:\n"+
                                "Позиций: %d/%d\n"+
                                "ТФ: %s\n"+
                                "Объем: %f\n"+
                                "Прибыль: %f\n"+
                                "Б/У: %f\n",
                                
                                TimeToString(TimeCurrent()),
                                
                                GridBuy.Size(), Max_pos,
                                (GridBuy.Size() > 0) ? IntegerToString(GridBuy.ActivatedLevelIdx+1) : "N/A",
                                state_buy.Volume,
                                state_buy.Profit,
                                state_buy.PriceBreakEven,
                                
                                GridSell.Size(), Max_pos,
                                (GridSell.Size() > 0) ? IntegerToString(GridSell.ActivatedLevelIdx+1) : "N/A",
                                state_sell.Volume,
                                state_sell.Profit,
                                state_sell.PriceBreakEven
                                );
  
  Comment(comment);
}


CATRPattern* CATRBot::CreatePattern(const ENUM_TIMEFRAMES _tf, const int _handle) {
  CATRPattern* zone = new CATRPattern();
  zone.Init(Sym.Name(), TF, _tf, _handle, 
            StringFormat("%s|%s|%d",
                         Logger.Name,
                         TimeframeToString(_tf),
                         _handle));
  return zone;
}

//+------------------------------------------------------------------+
//| Update all patterns
//+------------------------------------------------------------------+
void CATRBot::UpdatePatterns() {
  datetime dt = TimeCurrent();
  
  CATRPattern* zone;
  zone = PatternList.At(0);
  zone.Find(dt);
  Logger.Debug(StringFormat("%s/%d: TF=0; UP_SELL=%f; DOWN_BUY=%f",
                            __FUNCTION__, __LINE__,
                            zone.BarSellStart.GetValue(),
                            zone.BarBuyStart.GetValue()));
  if (PatternList.Total() <= 1) return;
  
  zone = PatternList.At(1);
  zone.Find(dt);
  Logger.Debug(StringFormat("%s/%d: TF=1; UP_SELL=%f; DOWN_BUY=%f",
                            __FUNCTION__, __LINE__,
                            zone.BarSellStart.GetValue(),
                            zone.BarBuyStart.GetValue()));  
  if (PatternList.Total() <= 2) return;

  zone = PatternList.At(2);  
  zone.Find(dt);  
  Logger.Debug(StringFormat("%s/%d: TF=2; UP_SELL=%f; DOWN_BUY=%f",
                            __FUNCTION__, __LINE__,
                            zone.BarSellStart.GetValue(),
                            zone.BarBuyStart.GetValue()));  
}

//+------------------------------------------------------------------+
//| Returns color for zone
//+------------------------------------------------------------------+
color CATRBot::GetColor(const int _zone_idx, const ENUM_POSITION_TYPE _dir) {
  if (_dir == POSITION_TYPE_SELL) {
    if (_zone_idx <= 0) return Resistance_color_1;
    if (_zone_idx <= 1) return Resistance_color_2;
    return Resistance_color_3;
  }
  
  if (_dir == POSITION_TYPE_BUY) {
    if (_zone_idx <= 0) return Support_color_1;
    if (_zone_idx <= 1) return Support_color_2;
    return Support_color_3;
  }  
  
  return clrYellow;
}

//+------------------------------------------------------------------+
//| Draw all patterns
//+------------------------------------------------------------------+
void CATRBot::Draw() {
  for (int i=0; i<PatternList.Total(); i++) {
    CATRPattern* zone = PatternList.At(i);
    zone.Draw(Sup_res_fill, Sup_res_width, Sup_res_style, 
              GetColor(i, POSITION_TYPE_BUY),
              GetColor(i, POSITION_TYPE_SELL));
  }
  
  GridBuy.Draw();
  GridSell.Draw();
}


//+------------------------------------------------------------------+
//| Init Bot
//+------------------------------------------------------------------+
void CATRBot::Init() {
  IsShowCommentActive = Is_comment;
  if ((MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE)) || MQLInfoInteger(MQL_OPTIMIZATION)) IsShowCommentActive = false;

  // Grid init
  GridBuy.Init(Sym.Name(), POSITION_TYPE_BUY, 
               Max_pos, Lot, DK_MinGridStepPnt, Multi, false, 0, 0, 
               Logger.Name + "." + "B", MagicBuy, TradeBuy);
  GridBuy.MinTPPnt = Min_takeP;
  GridBuy.Min_distance = Min_distance;
  GridBuy.Type_lot = Type_lot;
  GridBuy.Lot = Lot;
  GridBuy.Pair_ratio = Pair_ratio;
  GridBuy.RepeatSignal = RepeatSignal;
  GridBuy.Max_spread_buy = Max_spread_buy;
  GridBuy.SetLogger(GetPointer(Logger));
  GridBuy.SetRatios();

  GridSell.Init(Sym.Name(), POSITION_TYPE_SELL, 
                Max_pos, Lot, DK_MinGridStepPnt, Multi, false, 0, 0, 
                Logger.Name + "." + "S", MagicSell, TradeSell);
  GridSell.MinTPPnt = Min_takeP;
  GridSell.Min_distance = Min_distance;
  GridSell.Type_lot = Type_lot;
  GridSell.Lot = Lot;
  GridSell.Pair_ratio = Pair_ratio;
  GridSell.RepeatSignal = RepeatSignal;
  GridSell.Max_spread_buy = Max_spread_buy;
  GridSell.SetLogger(GetPointer(Logger));
  GridSell.SetRatios();

  // Init ATR indicators
  PatternList.Clear(); 
  
  ATR1Handle = iATR(Sym.Name(), EnumTimeframeCustomToDefault(Time_frame), Count_atrMTF_tf_1);
  PatternList.Add(CreatePattern(EnumTimeframeCustomToDefault(Time_frame), ATR1Handle));

  ATR2Handle = 0;
  if (Is_time_frame_2) {
    ATR2Handle = iATR(Sym.Name(), EnumTimeframeCustomToDefault(Time_frame_2), Count_atrMTF_tf_2);
    PatternList.Add(CreatePattern(EnumTimeframeCustomToDefault(Time_frame_2), ATR2Handle));
  }
  
  ATR3Handle = 0;
  if (Is_time_frame_3) {
    ATR3Handle = iATR(Sym.Name(), EnumTimeframeCustomToDefault(Time_frame_3), Count_atrMTF_tf_3);
    PatternList.Add(CreatePattern(EnumTimeframeCustomToDefault(Time_frame_3), ATR3Handle));
  }  

  // Bar detector init
  NewBarDetector.AddTimeFrame(TF);
  NewBarDetector.ResetAllLastBarTime();
  
  // Delete old objects from chart
  ObjectsDeleteAll(0, Logger.Name);
  UpdatePatterns();
  
//  OrderBuy = 0;
//  OrderSell = 0;

//  ZigZagPattern.Init(Sym.Name(), EnumTimeframeCustomToDefault(gTimeFrameZZ), gBarsBack, ZigZagHandle, Logger.Name);
//  ZigZagPattern.SetLogger(Logger);
//  ZigZagPattern.DrawEnable = gFlgDrawZZ;
//  
//  GetAllPos();
}

void CATRBot::GetAllPos() {
  PosList.Clear();
  
  CDKPositionInfo pos;
  for (int i=0; i<PositionsTotal(); i++) {
    if (!pos.SelectByIndex(i)) continue;
    if (pos.Magic() != MagicBuy && pos.Magic() != MagicSell) continue;
    if (pos.Symbol() != Sym.Name()) continue;
    
    PosList.Add(pos.Ticket());
  }
}

double CATRBot::GetTPDistRatio(const int _zone_idx) {
  if (_zone_idx <= 0) return (double)Percent_take_1/100;
  if (_zone_idx <= 1) return (double)Percent_take_2/100;
  return (double)Percent_take_3/100;
}

//+------------------------------------------------------------------+
//| Returns TP level price for pos
//+------------------------------------------------------------------+
double CATRBot::GetTPLevel(CDKPositionInfo& _pos) {
  if (_pos.PositionType() == POSITION_TYPE_BUY)  {
    CATRPattern* zone = PatternList.At(GridBuy.ActivatedLevelIdx); 
    return zone.BarSellStart.GetValue();
  }
  if (_pos.PositionType() == POSITION_TYPE_SELL) {
    CATRPattern* zone = PatternList.At(GridSell.ActivatedLevelIdx); 
    return zone.BarBuyStart.GetValue();    
  }
  
  return 0.0;  
}

//+------------------------------------------------------------------+
//| Returns TP as TOP level for BUY 
//| and as BOTTOM level for SELL.
//| Level is adjusted using % of TP from inputs
//| 
//| IMPORTANT:
//| Func updates BarBuyFirst/BarSellFirst for Zone
//+------------------------------------------------------------------+
double CATRBot::GetTPFromZones(CDKPositionInfo& _pos) {
  double tp_new = 0.0;
  if (_pos.PositionType() == POSITION_TYPE_BUY) {
    uint zone_idx = GridBuy.ActivatedLevelIdx;
    CATRPattern* zone = PatternList.At(zone_idx); 
    double zone_top = zone.BarSellStart.GetValue();
    double zone_bot = zone.BarBuyStart.GetValue();
    double tp_dist = MathAbs(zone_top-zone_bot);
    tp_new = zone_bot + tp_dist * GetTPDistRatio(zone_idx); 
    
    // #todo move set to upper func
    zone.BarBuyFirst.Init(Sym.Name(), TF, zone.BarSellStart.GetTime(), zone.BarSellStart.GetValue());
    zone.BarBuyFirstTP.Init(Sym.Name(), TF, TimeCurrent(), tp_new);
  }
  if (_pos.PositionType() == POSITION_TYPE_SELL) {
    uint zone_idx = GridSell.ActivatedLevelIdx;
    CATRPattern* zone = PatternList.At(zone_idx); 
    double zone_top = zone.BarBuyStart.GetValue();
    double zone_bot = zone.BarSellStart.GetValue();
    double tp_dist = MathAbs(zone_top-zone_bot);
    tp_new = zone_top - tp_dist * GetTPDistRatio(zone_idx);       
    
    // #todo move set to upper func
    zone.BarSellFirst.Init(Sym.Name(), TF, zone.BarBuyStart.GetTime(), zone.BarBuyStart.GetValue());
    zone.BarSellFirstTP.Init(Sym.Name(), TF, TimeCurrent(), tp_new);
  }
  
  return tp_new;
}

//+------------------------------------------------------------------+
//| Returns TP for pos which already had TP set.
//| New TP calcs as diff between old TP and zone movement distance
//| Is's looks like TRAINLING TP inside out
//+------------------------------------------------------------------+
double CATRBot::GetTPFromZoneShift(CDKPositionInfo& _pos) {
  // Move TP down/up while zone moving
  double tp_new = 0.0;
  if (_pos.PositionType() == POSITION_TYPE_BUY) {
    uint zone_idx = GridBuy.ActivatedLevelIdx;
    CATRPattern* zone = PatternList.At(zone_idx); 
    double zone_top = zone.BarSellStart.GetValue();
    double zone_init = zone.BarBuyFirst.GetValue();
    double tp_first = zone.BarBuyFirstTP.GetValue();
    tp_new = tp_first - (zone_init-zone_top);
  }
  if (_pos.PositionType() == POSITION_TYPE_SELL) {
    uint zone_idx = GridSell.ActivatedLevelIdx;
    CATRPattern* zone = PatternList.At(zone_idx); 
    double zone_bot = zone.BarBuyStart.GetValue();
    double zone_init = zone.BarSellFirst.GetValue();
    double tp_first = zone.BarSellFirstTP.GetValue();
    tp_new = tp_first + (zone_bot-zone_init);
  }      
  
  return tp_new;
}

//+------------------------------------------------------------------+
//| Returns new TP for pos.
//|  - TP is adjusted using % for TP from inputs.
//|  - TP for pos with no TP is calculated as B/S level
//|  - TP for pos with TP is calculaed as difference between first TP
//|    and current zones shift
//+------------------------------------------------------------------+
double CATRBot::GetTP(CDKPositionInfo& _pos) {
  double tp_new = 0.0;
  
  if (_pos.TakeProfit() > 0) 
    tp_new = GetTPFromZoneShift(_pos);
  else
    tp_new = GetTPFromZones(_pos);
  
  return NormalizeDouble(tp_new, Sym.Digits());
}

//+------------------------------------------------------------------+
//| Updates TP for all bot's pos                                                                  |
//+------------------------------------------------------------------+
void CATRBot::UpdateTP() {
  CDKPositionInfo pos;
  for (int i=0; i<PosList.Total(); i++) {
    long pos_ticket = PosList.At(i);
    if (!pos.SelectByTicket(PosList.At(i))) continue;
    
    CDKTrade trade = (pos.PositionType() == POSITION_TYPE_BUY) ? TradeBuy : TradeSell;
    double tp_old = pos.TakeProfit();    
    double tp_new = GetTP(pos);
    
    if (tp_old > 0.0 && pos.IsPriceGE(tp_new, tp_old)) continue;

    double price_to_close = pos.PriceToClose();
    if (!pos.IsPriceGT(tp_new, price_to_close)) {
      // New TP is <= price close -> Close pos by market
      if (trade.PositionClose(pos_ticket)) 
        Logger.Info(StringFormat("%s/%d: Close by market: TICKET=%I64u; DIR=%s; TP=%f -> %f; ASK/BID=%f", 
                                 __FUNCTION__, __LINE__,
                                 pos_ticket,
                                 PositionTypeToString(pos.PositionType()),
                                 tp_old, tp_new, price_to_close));
       else
        Logger.Error(StringFormat("%s/%d: Close by market: TICKET=%I64u; DIR=%s; TP=%f -> %f; ASK/BID=%f; RET_CODE=%d; ERR=%s", 
                                  __FUNCTION__, __LINE__,
                                  pos_ticket,
                                  PositionTypeToString(pos.PositionType()),
                                  tp_old, tp_new, price_to_close,
                                  trade.ResultRetcode(), trade.ResultRetcodeDescription()));
    }
    else {
      if (trade.PositionModify(pos.Ticket(), 0, tp_new))  
        Logger.Info(StringFormat("%s/%d: TICKET=%I64u; DIR=%s; TP=%f -> %f", 
                                  __FUNCTION__, __LINE__, 
                                  pos.Ticket(), PositionTypeToString(pos.PositionType()), 
                                  tp_old, tp_new));
      else
        Logger.Error(StringFormat("%s/%d: TICKET=%I64u; DIR=%s; TP=%f -> %f; RET_CODE=%d; ERR=%s", 
                                   __FUNCTION__, __LINE__, 
                                   pos.Ticket(), PositionTypeToString(pos.PositionType()), 
                                   tp_old, tp_new,
                                   trade.ResultRetcode(), trade.ResultRetcodeDescription()));
    }
  }
} 

void CATRBot::CheckAndRunHardSL(CDKGridATR& _grid) {
  if (Max_risk <= 0) return; // Option is off
  
  DKGridState state = _grid.GetState();
  if (state.Profit > -1*Max_risk) return; // Loss is avaliable
  
  if (Type_close == CLOSE_TYPE_FULL_SIDE) 
    if (_grid.CloseAll() > 0) 
      Logger.Warn(StringFormat("%s/%d: Close full side: ID=%s; DIR=%s; GRID_LOSS=%f>%f",
                               __FUNCTION__, __LINE__,
                               _grid.GetID(),
                               PositionTypeToString(_grid.GetDirection()),
                               -1*state.Profit,
                               Max_risk), true);
  
  if (Type_close == CLOSE_TYPE_MAX_LOSS) 
    if (_grid.CloseLast())
      Logger.Warn(StringFormat("%s/%d: Close last pos: ID=%s; DIR=%s; GRID_LOSS=%f>%f",
                               __FUNCTION__, __LINE__,
                               _grid.GetID(),
                               PositionTypeToString(_grid.GetDirection()),
                               -1*state.Profit,
                               Max_risk), true);
}

//+------------------------------------------------------------------+
//| OnTick Handler
//+------------------------------------------------------------------+
void CATRBot::OnTick(void) {
  // 1. Open new pos
  if (SetTypePos == TRADE_DIR_BUY || SetTypePos == TRADE_DIR_BUYSELL) 
    if (GridBuy.OpenNext(PatternList)) 
      Draw();
    
  if (SetTypePos == TRADE_DIR_SELL || SetTypePos == TRADE_DIR_BUYSELL)
    if (GridSell.OpenNext(PatternList)) 
      Draw();

  // 2. Update TP
  UpdateTP();
  
  // 3. Hard SL
  CheckAndRunHardSL(GridBuy);
  CheckAndRunHardSL(GridSell);  

  // 4. Update zones
  // Go next only if new bar detected
  if (!NewBarDetector.CheckNewBarAvaliable(TF)) return;
  Logger.Debug(StringFormat("New bar detected: TF=%s", TimeframeToString(TF)));
  
  UpdatePatterns();
  UpdateTP();
  Draw();
}

//+------------------------------------------------------------------+
//| OnTrade Handler
//+------------------------------------------------------------------+
void CATRBot::OnTrade(void) {
  // Sync market pos with grids
  GridBuy.OnTrade();
  GridSell.OnTrade();
  
  // Get all actual market pos
  GetAllPos();
}

//+------------------------------------------------------------------+
//| OnTimer Handler
//+------------------------------------------------------------------+
void CATRBot::OnTimer(void) {
  ShowComment();
}

//+------------------------------------------------------------------+
//| Constructor
//+------------------------------------------------------------------+
void CATRBot::CATRBot(void) {
}

//+------------------------------------------------------------------+
//| Destructor
//+------------------------------------------------------------------+
void CATRBot::~CATRBot(void) {
  PatternList.Clear();
}