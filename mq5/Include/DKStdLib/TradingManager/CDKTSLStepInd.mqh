//+------------------------------------------------------------------+
//|                                                CDKTSLStepInd.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include "CDKTrade.mqh"
#include "CDKTSLBase.mqh"

class CDKTSLStepInd : public CDKTSLBase {
protected:
  int                       IndHandle;
  int                       BufferNumber;
  uint                      Shift;
  
  double                    CDKTSLStepInd::GetIndValue();
  
public:
  void                      CDKTSLStepInd::CDKTSLStepInd(void);
  void                      CDKTSLStepInd::Init(const int _sl_distance_from_ind,
                                                const int _ind_handle,
                                                const int _buf_num,
                                                const uint _shift);
                                                
  bool                      CDKTSLStepInd::UpdateSL(CDKTrade& _trade, const double _new_sl, const bool _update_tp);
  bool                      CDKTSLStepInd::Update(CDKTrade& _trade, const bool _update_tp);
};

void CDKTSLStepInd::CDKTSLStepInd() {
  int ma_handle = iMA(m_symbol.Name(), PERIOD_M1, 10, 0, MODE_SMA, PRICE_CLOSE);
  Init(0, ma_handle, 0, 0);
}

void CDKTSLStepInd::Init(const int _sl_distance_from_ind,
                         const int _ind_handle,
                         const int _buf_num,
                         const uint _shift) {
  CDKTSLBase::Init(0, _sl_distance_from_ind);
  IndHandle = _ind_handle;
  BufferNumber = _buf_num;
  Shift = _shift;  
}

double CDKTSLStepInd::GetIndValue() {
  double val[];
  if (CopyBuffer(IndHandle, BufferNumber, Shift, 1, val) <= 0) return 0.0;
  
  return val[0];  
}

//+------------------------------------------------------------------+
//| Update public methods
//+------------------------------------------------------------------+
bool CDKTSLStepInd::UpdateSL(CDKTrade& _trade, const double _new_sl, const bool _update_tp) {
  ResRetcode = 0;
  ResRetcodeDescription = "";
  
  double curr_sl = StopLoss();
  SLNew = NormalizeDouble(_new_sl, m_symbol.Digits());
  
  double currTP = TakeProfit();
  TPNew = AddToPrice(PriceToClose(), Distance);
  TPNew = NormalizeDouble(TPNew, m_symbol.Digits());
  
  if (!IsPriceGT(SLNew, curr_sl)) SLNew = curr_sl;
  if (!(_update_tp && IsPriceGT(TPNew, currTP))) TPNew = currTP;
  
  if (CompareDouble(SLNew, curr_sl) && CompareDouble(TPNew, currTP)) {
    ResRetcode = TSL_CUSTOM_RET_CODE_PRICE_NOT_BETTER;
    ResRetcodeDescription = "new SL is not better than current";        
    return false;
  }
  
  bool res = false;
  // Current price is better than newTP or current price is worst new_sl ->
  // -> close pos immediatly, because it's impossible to set TP or SL
  if (IsPriceGE(PriceToClose(), TPNew) || IsPriceLE(PriceToClose(), SLNew))
    res = _trade.PositionClose(Ticket());
  else
    res = _trade.PositionModify(Ticket(), SLNew, TPNew);
    
  ResRetcode = _trade.ResultRetcode();
  ResRetcodeDescription = _trade.ResultRetcodeDescription();

  return res;
}

bool CDKTSLStepInd::Update(CDKTrade& _trade, const bool _update_tp) {
  double sl_new = AddToPrice(GetIndValue(), -1*GetDistance());
  return UpdateSL(_trade, sl_new, _update_tp);
}
