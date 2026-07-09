import React, { useState } from 'react';
import { ArrowLeft } from 'lucide-react';
import { Stock, mockStockDetail, mockChartData } from '../data';
import { AreaChart, Area, XAxis, YAxis, ResponsiveContainer, Line, ComposedChart, ReferenceLine } from 'recharts';

interface StockDetailProps {
  stock: Stock;
  onBack: () => void;
}

export const StockDetail: React.FC<StockDetailProps> = ({ stock, onBack }) => {
  const [activeTab, setActiveTab] = useState('分时');
  const tabs = ['分时', '日K', '周K', '月K'];

  // Use detail data if available, fallback to basic stock info
  const detail = mockStockDetail[stock.id] || {
    ...stock,
    prevClose: stock.price * 0.95,
    open: stock.price * 0.98,
    high: stock.price * 1.05,
    low: stock.price * 0.92,
    amplitude: '13.00%',
    avgPrice: stock.price * 0.99,
  };

  const isUp = detail.changePercent >= 0;
  const color = isUp ? '#2563eb' : '#475569'; // blue-600 or slate-600
  const lightColor = isUp ? 'rgba(37, 99, 235, 0.2)' : 'rgba(71, 85, 105, 0.2)';

  return (
    <div className="flex flex-col h-full bg-[#f8fafc] overflow-y-auto overflow-x-hidden custom-scrollbar relative animate-in slide-in-from-right-4 duration-300">
      {/* Decorative gradient blur */}
      <div className="absolute top-[-100px] right-[-50px] w-[300px] h-[300px] bg-blue-400/10 rounded-full blur-[80px] pointer-events-none"></div>

      {/* Header */}
      <div className="flex items-center justify-between px-6 pt-6 pb-4 z-10">
        <button 
          onClick={onBack}
          className="w-10 h-10 -ml-2 rounded-full bg-white/80 backdrop-blur-md flex items-center justify-center border border-slate-200 shadow-sm text-slate-500 hover:text-slate-900 hover:border-slate-300 transition-all"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div className="flex-1 text-center">
          <h1 className="text-xl font-black text-slate-900 tracking-tight">{detail.name}</h1>
          <div className="flex items-center justify-center gap-2 mt-0.5">
            <span className={`text-3xl font-black tracking-tight ${isUp ? 'text-blue-600' : 'text-slate-600'}`}>
              {detail.currencySymbol}{detail.price.toFixed(2)}
            </span>
            <span className={`text-xs font-black px-2 py-0.5 rounded-full ${isUp ? 'bg-blue-50 text-blue-600 border border-blue-100' : 'bg-slate-100 text-slate-500 border border-slate-200'}`}>
              {detail.changePercent > 0 ? '+' : ''}{detail.changePercent.toFixed(2)}%
            </span>
          </div>
        </div>
        <div className="w-10"></div> {/* Spacer for centering */}
      </div>

      {/* Grid Stats */}
      <div className="mx-6 p-5 bg-white/80 backdrop-blur-xl rounded-3xl shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] border border-white/60 mb-6 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none rounded-3xl"></div>
        <div className="grid grid-cols-3 gap-y-5 gap-x-2 text-[12px] relative z-10">
          <div className="flex flex-col items-center">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-tighter mb-1">Prev Close</span>
            <span className="font-black text-slate-800">{detail.currencySymbol}{detail.prevClose.toFixed(2)}</span>
          </div>
          <div className="flex flex-col items-center">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-tighter mb-1">Open</span>
            <span className={`font-black ${detail.open >= detail.prevClose ? 'text-blue-600' : 'text-slate-600'}`}>
              {detail.currencySymbol}{detail.open.toFixed(2)}
            </span>
          </div>
          <div className="flex flex-col items-center">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-tighter mb-1">High</span>
            <span className={`font-black ${detail.high >= detail.prevClose ? 'text-blue-600' : 'text-slate-600'}`}>
              {detail.currencySymbol}{detail.high.toFixed(2)}
            </span>
          </div>
          <div className="flex flex-col items-center">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-tighter mb-1">Low</span>
            <span className={`font-black ${detail.low >= detail.prevClose ? 'text-blue-600' : 'text-slate-600'}`}>
              {detail.currencySymbol}{detail.low.toFixed(2)}
            </span>
          </div>
          <div className="flex flex-col items-center">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-tighter mb-1">Amplitude</span>
            <span className="font-black text-slate-800">{detail.amplitude}</span>
          </div>
          <div className="flex flex-col items-center">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-tighter mb-1">Avg Price</span>
            <span className="font-black text-cyan-600">{detail.currencySymbol}{detail.avgPrice.toFixed(2)}</span>
          </div>
        </div>
      </div>

      {/* Chart Tabs */}
      <div className="px-6 mb-4">
        <div className="flex gap-2 justify-center overflow-x-auto hide-scrollbar pb-1">
          {tabs.map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`shrink-0 px-5 py-2 rounded-full text-xs font-bold transition-all duration-300 ${
                activeTab === tab 
                  ? 'bg-gradient-to-br from-slate-700 to-slate-800 text-white shadow-md shadow-slate-800/20' 
                  : 'bg-white text-slate-500 shadow-sm border border-slate-100 hover:border-slate-200 hover:bg-slate-50'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Chart Area */}
      <div className="w-full min-h-[350px] flex-1 pb-8 relative z-10">
        <ResponsiveContainer width="100%" height="100%">
          <ComposedChart data={mockChartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
            <defs>
              <linearGradient id="colorPrice" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={color} stopOpacity={0.3} />
                <stop offset="95%" stopColor={color} stopOpacity={0} />
              </linearGradient>
            </defs>
            <XAxis 
              dataKey="time" 
              axisLine={false} 
              tickLine={false} 
              tick={{ fontSize: 10, fill: '#9ca3af' }}
              interval="preserveStartEnd"
            />
            <YAxis 
              domain={['auto', 'auto']} 
              axisLine={false} 
              tickLine={false}
              tick={{ fontSize: 10, fill: '#9ca3af' }}
              orientation="left"
            />
            
            {/* Reference line for previous close */}
            <ReferenceLine y={detail.prevClose} stroke="#d1d5db" strokeDasharray="3 3" />
            
            {/* Main price line with fill */}
            <Area 
              type="monotone" 
              dataKey="price" 
              stroke={color} 
              strokeWidth={2}
              fillOpacity={1} 
              fill="url(#colorPrice)" 
              isAnimationActive={true}
            />
            
            {/* Average price line */}
            <Line 
              type="monotone" 
              dataKey="avgPrice" 
              stroke="#f59e0b" 
              strokeWidth={1.5} 
              dot={false}
              isAnimationActive={true}
            />
          </ComposedChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};
