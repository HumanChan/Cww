import { Stock, StockDetailData, ChartDataPoint } from './types';

export const mockWatchlist: Stock[] = [
  {
    id: '1',
    name: '兆易创新',
    market: '沪市',
    code: '603986',
    turnover: '376.54亿',
    price: 663.49,
    changePercent: 10.00,
    currencySymbol: '¥',
  },
  {
    id: '2',
    name: '兆易创新',
    market: '港股',
    code: '03986',
    turnover: '45.76亿',
    price: 940.50,
    changePercent: 21.75,
    currencySymbol: 'HK$',
  },
  {
    id: '3',
    name: '普冉股份',
    market: '沪市',
    code: '688766',
    turnover: '85.57亿',
    price: 762.07,
    changePercent: 9.81,
    currencySymbol: '¥',
  },
  {
    id: '4',
    name: '德明利',
    market: '深市',
    code: '001309',
    turnover: '12.34亿',
    price: 860.48,
    changePercent: -2.34,
    currencySymbol: '¥',
  },
  {
    id: '5',
    name: '中芯国际',
    market: '科创',
    code: '688981',
    turnover: '210.00亿',
    price: 45.67,
    changePercent: 5.43,
    currencySymbol: '¥',
  },
];

export const mockStockDetail: Record<string, StockDetailData> = {
  '1': {
    ...mockWatchlist[0],
    prevClose: 603.17,
    open: 633.00,
    high: 663.49,
    low: 630.00,
    amplitude: '5.55%',
    avgPrice: 646.20,
  }
};

// Generate somewhat realistic looking intraday chart data based on the screenshot
export const generateChartData = (): ChartDataPoint[] => {
  const data: ChartDataPoint[] = [];
  let currentPrice = 630;
  let avgPrice = 635;
  
  const times = ['09:30', '10:13', '10:56', '13:08', '13:51', '15:00'];
  let timeIndex = 0;

  for (let i = 0; i < 60; i++) {
    // Simulate the dip and then sharp rise to limit up as seen in the image
    if (i < 20) {
      currentPrice += (Math.random() - 0.6) * 15;
      avgPrice += (Math.random() - 0.4) * 2;
    } else if (i < 30) {
      currentPrice += (Math.random() - 0.2) * 20; // Sharp rise
      avgPrice += (Math.random() - 0.1) * 5;
    } else {
      currentPrice = 663.49; // Hit limit up and stay there
      avgPrice += (663.49 - avgPrice) * 0.05; // Average catches up slowly
    }

    let timeStr = '';
    if (i % 12 === 0 && timeIndex < times.length) {
      timeStr = times[timeIndex];
      timeIndex++;
    }

    data.push({
      time: timeStr,
      price: Number(currentPrice.toFixed(2)),
      avgPrice: Number(avgPrice.toFixed(2)),
    });
  }
  return data;
};

export const mockChartData = generateChartData();
