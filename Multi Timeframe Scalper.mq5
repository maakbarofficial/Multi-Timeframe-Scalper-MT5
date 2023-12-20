#property copyright "Muhammad Ali Akbar"
#property link "https://www.aliakbar.vercel.app"
#property version "1.00"

#include <Trade/Trade.mqh>

int handleTrendMAFast;
int handleTrendMASlow;

int handleMAFast;
int handleMAMiddle;
int handleMASlow;

CTrade trade;

double lotssize = 0.05;
int magicNum = 12345;

int OnInit()
{

  trade.SetExpertMagicNumber(magicNum);

  handleTrendMAFast = iMA(_Symbol, PERIOD_H1, 8, 0, MODE_EMA, PRICE_CLOSE);
  handleTrendMASlow = iMA(_Symbol, PERIOD_H1, 21, 0, MODE_EMA, PRICE_CLOSE);

  handleMAFast = iMA(_Symbol, PERIOD_M5, 8, 0, MODE_EMA, PRICE_CLOSE);
  handleMAMiddle = iMA(_Symbol, PERIOD_M5, 13, 0, MODE_EMA, PRICE_CLOSE);
  handleMASlow = iMA(_Symbol, PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);

  return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
  double MATrendFast[], MATrendSlow[];
  CopyBuffer(handleTrendMAFast, 0, 0, 1, MATrendFast);
  CopyBuffer(handleTrendMASlow, 0, 0, 1, MATrendSlow);

  double MAFast[], MAMiddle[], MASlow[];
  CopyBuffer(handleMAFast, 0, 0, 1, MAFast);
  CopyBuffer(handleMAMiddle, 0, 0, 1, MAMiddle);
  CopyBuffer(handleMASlow, 0, 0, 1, MASlow);

  double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

  int trendDirection = 0;

  if (MATrendFast[0] > MATrendSlow[0] && bidPrice > MATrendFast[0])
  {
    trendDirection = 1;
  }
  else if (MATrendFast[0] < MATrendSlow[0] && bidPrice < MATrendFast[0])
  {
    trendDirection = -1;
  }

  int positions = 0;
  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    ulong posTicket = PositionGetTicket(i);
    if (PositionSelectByTicket(posTicket))
    {
      if (PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magicNum)
      {
        positions = positions + 1;

        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
          if (PositionGetDouble(POSITION_VOLUME) >= lotssize)
          {
            double tp = PositionGetDouble(POSITION_PRICE_OPEN) + (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL));

            if (bidPrice >= tp)
            {
              trade.PositionClosePartial(posTicket, NormalizeDouble(PositionGetDouble(POSITION_VOLUME) / 2, 2));
              {
                double sl = PositionGetDouble(POSITION_PRICE_OPEN);
                sl = NormalizeDouble(sl, _Digits);

                if (trade.PositionModify(posTicket, sl, 0))
                {
                }
              }
            }
          }
          else
          {
            int lowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 3, 1);
            double sl = iLow(_Symbol, PERIOD_M5, lowest);
            sl = NormalizeDouble(sl, _Digits);

            if (sl > PositionGetDouble(POSITION_SL))
            {
              if (trade.PositionModify(posTicket, sl, 0))
              {
              }
            }
          }
        }

        else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
          if (PositionGetDouble(POSITION_VOLUME) >= lotssize)
          {
            double tp = PositionGetDouble(POSITION_PRICE_OPEN) - (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN));

            if (bidPrice <= tp)
            {
              trade.PositionClosePartial(posTicket, NormalizeDouble(PositionGetDouble(POSITION_VOLUME) / 2, 2));
              {
                double sl = PositionGetDouble(POSITION_PRICE_OPEN);
                sl = NormalizeDouble(sl, _Digits);

                if (trade.PositionModify(posTicket, sl, 0))
                {
                }
              }
            }
          }
          else
          {
            int highest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 3, 1);
            double sl = iLow(_Symbol, PERIOD_M5, highest);
            sl = NormalizeDouble(sl, _Digits);

            if (sl < PositionGetDouble(POSITION_SL))
            {
              if (trade.PositionModify(posTicket, sl, 0))
              {
              }
            }
          }
        }
      }
    }
  }

  int orders = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
  {
    ulong orderTicket = OrderGetTicket(i);
    if (OrderSelect(orderTicket))
    {
      if (OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == magicNum)
      {
        if (OrderGetInteger(ORDER_TIME_SETUP) < TimeCurrent() - 30 * PeriodSeconds(PERIOD_M1))
        {
          trade.OrderDelete(orderTicket);
        }
        orders = orders + 1;
      }
    }
  }

  if (trendDirection == 1)
  {
    if (MAFast[0] > MAMiddle[0] && MAMiddle[0] > MASlow[0])
    {
      if (bidPrice <= MAFast[0])
      {
        if (positions + orders <= 0)
        {
          int indexHighest = iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5, 1);
          double highPrice = iHigh(_Symbol, PERIOD_M5, indexHighest);
          double highestPrice = NormalizeDouble(highPrice, _Digits);

          double sl = iLow(_Symbol, PERIOD_M5, 0) + 30 * _Point;
          sl = NormalizeDouble(sl, _Digits);

          double tp = highestPrice + (highestPrice - sl);
          tp = NormalizeDouble(tp, _Digits);

          trade.BuyStop(lotssize, highestPrice, _Symbol, sl, tp);
        }
      }
    }
  }
  else if (trendDirection == -1)
  {
    if (MAFast[0] < MAMiddle[0] && MAMiddle[0] < MASlow[0])
    {
      if (bidPrice >= MAFast[0])
      {
        if (positions + orders <= 0)
        {
          int indexLowest = iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5, 1);
          double lowPrice = iLow(_Symbol, PERIOD_M5, indexLowest);
          double lowestPrice = NormalizeDouble(lowPrice, _Digits);

          double sl = iHigh(_Symbol, PERIOD_M5, 0) - 30 * _Point;
          sl = NormalizeDouble(sl, _Digits);

          double tp = lowestPrice - (sl - lowestPrice);
          tp = NormalizeDouble(tp, _Digits);

          trade.SellStop(lotssize, lowestPrice, _Symbol, sl, tp);
        }
      }
    }
  }

  Comment("\nFast Trend MA: ", DoubleToString(MATrendFast[0], _Digits),
          "\nSlow Trend MA: ", DoubleToString(MATrendSlow[0], _Digits),
          "\nTrend Direction: ", trendDirection,
          "\n",
          "\nFast MA: ", DoubleToString(MAFast[0], _Digits),
          "\nMiddle MA: ", DoubleToString(MAMiddle[0], _Digits),
          "\nSlow MA: ", DoubleToString(MASlow[0], _Digits),
          "\n",
          "\nPositions: ", positions,
          "\nOrders: ", orders);
}
