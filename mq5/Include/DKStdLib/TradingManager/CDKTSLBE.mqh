//+------------------------------------------------------------------+
//|                                                     CDKTSLBE.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
  
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

// # Description
// Moves SL of current pos to PriceOpen()+ExtraShiftPoint
// when ActivationPrice passed
//
// #Usage 
//
////+------------------------------------------------------------------+
////| Serves BE
////+------------------------------------------------------------------+
//void CZigzagerBot::MovePosToBE(const ulong _pos_id) {
//  int activation_distance_from_open_point = 500;
//  int be_extra_shift_from_open_point = 100;
//  
//  if (activation_distance_from_open_point <= 0) return;
//
//  CDKTSLBE pos;
//  if (!pos.SelectByTicket(_pos_id)) return; // No pos found
//
//  double sl_old = pos.StopLoss();
//  pos.Init(activation_distance_from_open_point, be_extra_shift_from_open_point);
//  bool res = pos.Update(Trade, false);
//  pos.SelectByTicket(_pos_id);
//  double sl_new = pos.StopLoss();
//  
//  if (!res) 
//    Logger.Assert(pos.ResultRetcode() >= ERR_USER_ERROR_FIRST,
//                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__, 
//                               _pos_id, pos.ResultRetcode(), pos.ResultRetcodeDescription()), DEBUG,
//                  StringFormat("%s/%d: T=%I64u; RET_CODE=%d; ERR=%s", __FUNCTION__, __LINE__, 
//                               _pos_id, pos.ResultRetcode(), pos.ResultRetcodeDescription()), ERROR);
//  else
//    Logger.Info(StringFormat("%s/%d: T=%I64u; RET_CODE=DONE; SL=%f->%f", __FUNCTION__, __LINE__, _pos_id, sl_old, sl_new));
//}

#include "CDKTrade.mqh"
#include "CDKTSLBase.mqh"

class CDKTSLBE : public CDKTSLBase {
  int                       ExtraShiftPoint;
public:
  void                      CDKTSLBE::CDKTSLBE();
  void                      CDKTSLBE::Init(const int _activation_distance_from_open_point, const int _extra_shift_pnt=0);
  bool                      CDKTSLBE::Update(CDKTrade& _trade, const bool _update_tp);
};

void CDKTSLBE::CDKTSLBE() {
  ExtraShiftPoint = 0;
  SetDistance(0);
  Init(0, 0);
}

void CDKTSLBE::Init(const int _activation_distance_from_open_point, const int _extra_shift_pnt=0) {
  ExtraShiftPoint = _extra_shift_pnt;
  SetActivation(_activation_distance_from_open_point);
  SetDistance(0);
}

bool CDKTSLBE::Update(CDKTrade& _trade, const bool _update_tp) {
  double new_sl = AddToPrice(PriceOpen(), ExtraShiftPoint);
  return CDKTSLBase::UpdateSL(_trade, new_sl, _update_tp);
}