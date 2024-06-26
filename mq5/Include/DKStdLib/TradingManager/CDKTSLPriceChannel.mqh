//+------------------------------------------------------------------+
//|                                           CDKTSLPriceChannel.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include "CDKTrade.mqh"
#include "CDKTSLBase.mqh"

enum ENUM_CHANNEL_BORDER {
  CHANNEL_BORDER_WICK,
  CHANNEL_BORDER_BODY
};

class CDKTSLPriceChannel : public CDKTSLBase {
protected:
  ENUM_TIMEFRAMES           Period;
  uint                      Shift;
  uint                      Depth;
  ENUM_CHANNEL_BORDER       BorderType;
  int                       ExtraDistanceShift;
  
public:
  void                      CDKTSLPriceChannel::CDKTSLPriceChannel(void);
  void                      CDKTSLPriceChannel::Init(const int _activation_distance_from_open_point, 
                                                     const ENUM_TIMEFRAMES _period,
                                                     const uint _shift,
                                                     const uint _depth,
                                                     const ENUM_CHANNEL_BORDER _bordertype,
                                                     const int _extra_distance_shift);
  bool                      CDKTSLPriceChannel::Update(CDKTrade& _trade, const bool _update_tp);
};

void CDKTSLPriceChannel::CDKTSLPriceChannel() {
  CDKTSLBase::Init(0, 0);
  Init(0, PERIOD_M1, 0, 10, CHANNEL_BORDER_WICK, 0);
}

void CDKTSLPriceChannel::Init(const int _activation_distance_from_open_point, 
                              const ENUM_TIMEFRAMES _period,
                              const uint _shift,
                              const uint _depth,
                              const ENUM_CHANNEL_BORDER _border_type,
                              const int _extra_distance_shift) {
  CDKTSLBase::Init(_activation_distance_from_open_point, 0);
  Period = _period;
  Shift = _shift;
  Depth = _depth;
  BorderType = _border_type;
  ExtraDistanceShift = _extra_distance_shift;
}

bool CDKTSLPriceChannel::Update(CDKTrade& _trade, const bool _update_tp) {

  double sl_new = 0.0;
  if (PositionType() == POSITION_TYPE_BUY) {
    if (BorderType == CHANNEL_BORDER_BODY) {
      double open = iLow(m_symbol.Name(), Period, iLowest(m_symbol.Name(), Period, MODE_OPEN, Depth, Shift));
      double close = iLow(m_symbol.Name(), Period, iLowest(m_symbol.Name(), Period, MODE_CLOSE, Depth, Shift));
      sl_new = MathMin(open, close);
    }
    else
      sl_new = iLow(m_symbol.Name(), Period, iLowest(m_symbol.Name(), Period, MODE_LOW, Depth, Shift));
  }
  else {
    if (BorderType == CHANNEL_BORDER_BODY) {
      double open = iHigh(m_symbol.Name(), Period, iHighest(m_symbol.Name(), Period, MODE_OPEN, Depth, Shift));
      double close = iHigh(m_symbol.Name(), Period, iHighest(m_symbol.Name(), Period, MODE_CLOSE, Depth, Shift));
      sl_new = MathMax(open, close);
    }
    else
      sl_new = iHigh(m_symbol.Name(), Period, iHighest(m_symbol.Name(), Period, MODE_HIGH, Depth, Shift));  
  }  
  sl_new = AddToPrice(sl_new, -1*ExtraDistanceShift);
  
  return CDKTSLBase::UpdateSL(_trade, sl_new, _update_tp);
}
