export interface Stock {
  id: string;
  name: string;
  market: string;
  code: string;
  turnover: string;
  price: number;
  changePercent: number;
  currencySymbol: string;
}

export interface StockDetailData extends Stock {
  prevClose: number;
  open: number;
  high: number;
  low: number;
  amplitude: string;
  avgPrice: number;
}

export interface ChartDataPoint {
  time: string;
  price: number;
  avgPrice: number;
}
