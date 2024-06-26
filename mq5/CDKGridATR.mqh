//+------------------------------------------------------------------+
//|                                                   CDKGridATR.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include "Include\DKStdLib\TradingManager\CDKGridOneDirStepPos.mqh";
#include "Include\DKStdLib\Common\CDKBarTag.mqh";
#include "CATRPattern.mqh"

enum ENUM_TYPE_LOT {
  TYPE_LOT_FIXED          = 0, // Фиксированный лот
  TYPE_LOT_FIBO           = 1, // Мартингейл (ориг. Фибоначчи)
  TYPE_LOT_MARTIN         = 2, // Мартингейл
  TYPE_LOT_DALAMBER       = 3, // Мартингейл (ориг. Даламбер)
  TYPE_LOT_PAIR           = 4  // Парный коэффициент
};

class CDKGridATR : public CDKGridOneDirStepPos {
protected:
  CArrayObj                PatternList;
public:
  ENUM_TYPE_LOT            Type_lot;
  double                   Lot;
  uint                     Pair_ratio;
  
  bool                     RepeatSignal;
  
  uint                     Max_spread_buy;
  
  uint                     MinTPPnt;
  uint                     Min_distance;
  uint                     ActivatedLevelIdx;  
  
  void                     CDKGridATR::~CDKGridATR();
  void                     CDKGridATR::SetRatios();

  bool                     CDKGridATR::UpdateLevelPass();
  
  bool                     CDKGridATR::CheckEntryForEmptyGrid();
  bool                     CDKGridATR::CheckEntryForNextPos();
  bool                     CDKGridATR::CheckEntry();
  
  ulong                    CDKGridATR::OpenNext(CArrayObj& _pattern_list, 
                                                const bool aIgnoreEntryCheck = false, 
                                                const string _pos_comment = "");
                                                
  void                     CDKGridATR::Draw();                                     
                                                
                                                
  void                     CDKGridATR::OnTrade();
};

//+------------------------------------------------------------------+
//| Updates level idx which has passed
//| The check starts from level already have passed previos time
//+------------------------------------------------------------------+
bool CDKGridATR::UpdateLevelPass() {
  uint idx_start = 0;
  if (Size() > 0) idx_start = ActivatedLevelIdx+1;
  
  for(int i=(int)idx_start; i<PatternList.Total(); i++) {
    CATRPattern* zone = PatternList.At(i);
    
    if (GetDirection() == POSITION_TYPE_BUY) {
      if (!zone.BuyEnabled) continue;
      if (zone.BarBuyInit.GetTime() <= 0)continue;
      
      datetime level_dt = zone.BarBuyInit.GetTime();
      double level_price = zone.BarBuyStart.GetValue();
      double level_opposite_price = zone.BarSellStart.GetValue();
      int between_level_dist_pnt = m_symbol.PriceToPoints(level_opposite_price-level_price);
      double curr_price = m_symbol.GetPriceToOpen(POSITION_TYPE_BUY);
      bool res = (curr_price < level_price && between_level_dist_pnt >= (int)Min_distance);
      if (DEBUG >= m_logger.Level) // if statment to prevent StringFormat every time
        Log(StringFormat("CDKGridATR::CheckLevelPass(LEV=%d): RES=%d | GID=%s | DIR=%s | SIZE=%d/%d | LEV_HIT=%d: %f%s%f | BTW_LEV=%d: %d%s%d", 
                         i, res, m_id, GetDirectionDescription(), Size(), m_max_pos_count, 
                         curr_price > level_price, // LEV_HIT
                         curr_price,
                         (res) ? "<=" : ">",
                         level_price,
                         between_level_dist_pnt >= (int)Min_distance, // BTW_LEV
                         between_level_dist_pnt,
                         (between_level_dist_pnt >= (int)Min_distance) ? ">=" : "<",
                         Min_distance
                         ), DEBUG);  

      if (res) {
        ActivatedLevelIdx = i;
        return true;
      }
    }
    
    if (GetDirection() == POSITION_TYPE_SELL) {
      if (!zone.SellEnabled) continue;
      if (zone.BarSellInit.GetTime() <= 0)continue;
      
      datetime level_dt = zone.BarSellInit.GetTime();
      double level_price = zone.BarSellStart.GetValue();
      double level_opposite_price = zone.BarBuyStart.GetValue();
      int between_level_dist_pnt = m_symbol.PriceToPoints(level_price - level_opposite_price);      
      double curr_price = m_symbol.GetPriceToOpen(POSITION_TYPE_SELL);
      bool res = (curr_price > level_price && between_level_dist_pnt >= (int)Min_distance);
      if (DEBUG >= m_logger.Level) // if statment to prevent StringFormat every time
        Log(StringFormat("CDKGridATR::CheckLevelPass(LEV=%d): RES=%d | GID=%s | DIR=%s | SIZE=%d/%d | LEV_HIT=%d: %f%s%f | BTW_LEV=%d: %d%s%d", 
                         i, res, m_id, GetDirectionDescription(), Size(), m_max_pos_count, 
                         curr_price > level_price, // LEV_HIT
                         curr_price,
                         (res) ? ">=" : "<",
                         level_price,
                         between_level_dist_pnt >= (int)Min_distance, // BTW_LEV
                         between_level_dist_pnt,
                         (between_level_dist_pnt >= (int)Min_distance) ? ">=" : "<",
                         Min_distance
                         ), DEBUG);  


      if (res) {
        ActivatedLevelIdx = i;
        return true;    
      }
    }    
  }
  
  return false;
}

//+------------------------------------------------------------------+
//| Check for empty grid is it possible to open first pos.
//| It's ok to open pos if price hits or cross Bar*Start.Value level
//| of any ATR zone.
//+------------------------------------------------------------------+
bool CDKGridATR::CheckEntryForEmptyGrid() {
  if (Size() > 0) return false;
  return UpdateLevelPass();
}

//+------------------------------------------------------------------+
//| Check for empty grid is it possible to open first pos.
//| It's ok to open pos if price hits or cross Bar*Start.Value level
//| of any ATR zone.
//+------------------------------------------------------------------+
bool CDKGridATR::CheckEntryForNextPos() {
  if (Size() <= 0) return false;
  
  CDKPositionInfo pos;
  if (!pos.SelectByTicket(m_positions.At(0))) return false;
  
  DKGridState state = GetState();
  double tp = pos.TakeProfit();
  if (tp <= 0.0) return false; // Pos has no TP. It's impossible to calc TP distance
  
  int tp_dist = 0;
  if (GetDirection() == POSITION_TYPE_BUY)  tp_dist = m_symbol.PriceToPoints(tp - state.PriceBreakEven);
  if (GetDirection() == POSITION_TYPE_SELL) tp_dist = m_symbol.PriceToPoints(state.PriceBreakEven - tp);
  
  bool res = (tp_dist <= (int)MinTPPnt);  
  if (res)
    res = res;
    
  if (DEBUG >= m_logger.Level)    
    Log(StringFormat("CDKGridATR::CheckEntryForNextPos(): RES=%d | GID=%s | DIR=%s | SIZE=%d/%d | TP=%d %s %d", 
                     res, m_id, GetDirectionDescription(), Size(), m_max_pos_count, 
                     tp_dist, 
                     (res) ? "<=" : ">",
                     MinTPPnt), DEBUG);  
  return res;    
}

//+------------------------------------------------------------------+
//| CheckEntry
//+------------------------------------------------------------------+
bool CDKGridATR::CheckEntry() {
  // 0. Max spread for BUY check
  if (GetDirection() == POSITION_TYPE_BUY && Max_spread_buy > 0) {
    if (!m_symbol.RefreshRates()) return false;
    if (MathAbs(m_symbol.Spread()) > (int)Max_spread_buy) 
      return false;
  }
  
  // 1. Grid entry check for empty check
  if (Size() <= 0) return CheckEntryForEmptyGrid();

  // 2. Grid size less max and grid step
  if (!CDKGridOneDirStepPos::CheckEntry()) return false;
  
  // 3. Grid entry check for next order
  return CheckEntryForNextPos();
}

ulong CDKGridATR::OpenNext(CArrayObj& _pattern_list, 
                           const bool aIgnoreEntryCheck = false, 
                           const string _pos_comment = "") {
                           
  PatternList = _pattern_list;                           
  if (!aIgnoreEntryCheck && !CheckEntry())
    return 0;

  ulong ticket = CDKGridOneDirStepPos::OpenNext(true, _pos_comment); 
  
  // Block repeat signal
  if (ticket > 0 && !RepeatSignal) {
    CATRPattern* zone = PatternList.At(ActivatedLevelIdx); 
    if (GetDirection() == POSITION_TYPE_BUY) zone.BuyEnabled = false;
    if (GetDirection() == POSITION_TYPE_SELL) zone.SellEnabled = false;
  }
    
  // Try to set total grid TP for opened pos
  if (Size() > 1 && ticket > 0) {
    CDKPositionInfo pos;
    if (Get(0, pos)) SetSLTP(pos.StopLoss(), pos.TakeProfit());
  }
  
  return ticket;
}

void CDKGridATR::Draw() {
  if (Size() <= 0) return;
  
  DKGridState state = GetState();
  TextCreate(0,               // ID графика 
             StringFormat("%s|%s|%s|BE", 
                          m_comment_prefix, 
                          GetID(),
                          (GetDirection() == POSITION_TYPE_BUY) ? "BUY" : "SELL"), // name
             0,             // номер подокна 
             TimeCurrent(),            // время точки привязки
             state.PriceBreakEven,           // цена точки привязки
             "*", //"ê",              // сам текст 
             "Arial", //"Wingdings",             // шрифт 
             12,             // размер шрифта 
             (GetDirection() == POSITION_TYPE_BUY) ? clrGreen : clrRed,               // цвет 
             0.0,                // наклон текста 
             ANCHOR_CENTER, // способ привязки 
             false,               // на заднем плане 
             false,          // выделить для перемещений 
             false,              // скрыт в списке объектов 
             0);                // приоритет на нажатие мышью        
}

//+------------------------------------------------------------------+
//| Set Ratio for every possible grid size and for Type_lot
//+------------------------------------------------------------------+
void CDKGridATR::SetRatios() {
  for(uint i=1; i<m_max_pos_count; i++) {
    if (Type_lot == TYPE_LOT_FIXED)    SetRatio(i, 1.0);
    if (Type_lot == TYPE_LOT_FIBO ||
        Type_lot == TYPE_LOT_MARTIN ||
        Type_lot == TYPE_LOT_DALAMBER) SetRatio(i, Multi);
    if (Type_lot == TYPE_LOT_PAIR && Pair_ratio > 1)     
      if (i%Pair_ratio == 0) SetRatio(i, Multi);
      else SetRatio(i, 1.0);
  }
}

void CDKGridATR::OnTrade() {
  CDKGridBase::OnTrade();
  if (Size() <= 0) ActivatedLevelIdx = 0;
}

void CDKGridATR::~CDKGridATR() {
}