import React, { useState } from 'react';
import { Search, Moon, Plus, Settings, GripVertical } from 'lucide-react';
import { mockWatchlist } from '../data';
import { Stock } from '../types';

interface WatchlistProps {
  onSelectStock: (stock: Stock) => void;
}

export const Watchlist: React.FC<WatchlistProps> = ({ onSelectStock }) => {
  const [activeTab, setActiveTab] = useState('GD');
  const tabs = ['GD', 'Chip', 'HK', 'US', 'KR', 'TW'];

  return (
    <div className="flex flex-col h-full bg-[#f8fafc] overflow-hidden relative">
      {/* Header Area */}
      <div className="px-6 pt-6 pb-2">
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-2xl font-black text-slate-900">Watchlist</h3>
          <button className="w-10 h-10 rounded-full bg-white flex items-center justify-center border border-slate-200 shadow-sm text-slate-500 hover:text-slate-900 hover:border-slate-300">
            <Moon className="w-5 h-5" />
          </button>
        </div>

        <div className="relative mb-6 group">
          <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
            <Search className="w-4 h-4 text-slate-400 group-focus-within:text-blue-500 transition-colors" />
          </div>
          <input 
            type="text" 
            placeholder="Search stocks..." 
            className="w-full bg-white border border-slate-200 shadow-sm rounded-2xl py-3 pl-10 pr-5 text-sm text-slate-900 placeholder:text-slate-400 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 focus:outline-none transition-all"
          />
        </div>

        {/* Tabs */}
        <div className="flex gap-2 mb-2 overflow-x-auto hide-scrollbar pb-2">
          {tabs.map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`shrink-0 px-5 py-2 rounded-full text-xs font-bold transition-all duration-300 ${
                activeTab === tab 
                  ? 'bg-gradient-to-br from-blue-500 to-blue-600 text-white shadow-md shadow-blue-500/20' 
                  : 'bg-white text-slate-500 shadow-sm border border-slate-100 hover:border-slate-200 hover:bg-slate-50'
              }`}
            >
              {tab}
            </button>
          ))}
          <div className="flex items-center px-2 space-x-2 border-l border-slate-200 ml-1 shrink-0">
            <button className="text-slate-400 hover:text-slate-600 p-2 bg-white rounded-full border border-slate-100 shadow-sm">
              <Plus className="w-4 h-4" />
            </button>
            <button className="text-slate-400 hover:text-slate-600 p-2 bg-white rounded-full border border-slate-100 shadow-sm">
              <Settings className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto px-6 py-2 space-y-4 custom-scrollbar">
        {mockWatchlist.map((stock) => (
          <div 
            key={stock.id} 
            onClick={() => onSelectStock(stock)}
            className="p-4 bg-white/80 backdrop-blur-xl rounded-3xl shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] border border-white/60 cursor-pointer active:scale-[0.98] transition-all hover:shadow-[0_8px_30px_-4px_rgba(0,0,0,0.1)] flex items-center justify-between group relative overflow-hidden"
          >
            {/* Subtle gradient shine */}
            <div className="absolute inset-0 bg-gradient-to-br from-white/40 to-transparent pointer-events-none rounded-3xl"></div>
            
            <div className="flex items-center gap-3 relative z-10">
              <div>
                <div className="flex items-baseline gap-2 mb-1">
                  <h3 className="text-lg font-black text-slate-900 tracking-tight leading-tight">{stock.name}</h3>
                  <span className="text-[10px] font-bold text-blue-500 uppercase tracking-tighter bg-blue-50 px-2 py-0.5 rounded">
                    {stock.market}
                  </span>
                </div>
                <div className="flex items-center text-xs text-slate-500 gap-2 font-medium">
                  <span className="font-mono text-slate-400">{stock.code}</span>
                  <span>Turnover {stock.currencySymbol}{stock.turnover}</span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-4 relative z-10">
              <div className="text-right">
                <div className={`text-xl font-black tracking-tight ${stock.changePercent >= 0 ? 'text-blue-600' : 'text-slate-600'}`}>
                  {stock.currencySymbol}{stock.price.toFixed(2)}
                </div>
                <div className="mt-1 flex gap-1 justify-end">
                   <span className={`text-[11px] font-black px-2 py-0.5 rounded-full ${
                    stock.changePercent >= 0 ? 'bg-blue-50 text-blue-600' : 'bg-slate-100 text-slate-500'
                  }`}>
                    {stock.changePercent > 0 ? '+' : ''}{stock.changePercent.toFixed(2)}%
                  </span>
                </div>
              </div>
              <GripVertical className="w-5 h-5 text-slate-300 cursor-grab active:cursor-grabbing opacity-50 group-hover:opacity-100 transition-opacity" />
            </div>
          </div>
        ))}
        <div className="h-8"></div> {/* Bottom padding */}
      </div>
    </div>
  );
};
