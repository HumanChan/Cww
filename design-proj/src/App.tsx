import React, { useState } from 'react';
import { Watchlist } from './components/Watchlist';
import { StockDetail } from './components/StockDetail';
import { Stock } from './types';

export default function App() {
  const [selectedStock, setSelectedStock] = useState<Stock | null>(null);

  return (
    <div className="min-h-screen bg-[#020617] text-slate-100 flex items-center justify-center p-0 sm:p-4 md:p-8 font-sans relative overflow-hidden">
      {/* Background Orbs */}
      <div className="absolute top-[-200px] left-[-100px] w-[500px] h-[500px] bg-blue-600/20 rounded-full blur-[120px] pointer-events-none hidden sm:block"></div>
      <div className="absolute bottom-[-200px] right-[-100px] w-[500px] h-[500px] bg-cyan-600/20 rounded-full blur-[120px] pointer-events-none hidden sm:block"></div>

      {/* Mobile constraint container for desktop view, full screen on mobile */}
      <div className="w-full h-[100dvh] sm:h-[850px] sm:max-w-[400px] relative overflow-hidden bg-[#1E293B] sm:rounded-[50px] sm:border-[8px] sm:border-slate-800 sm:shadow-2xl flex flex-col z-10">
        
        {/* Mobile Notch (Desktop only) */}
        <div className="hidden sm:flex h-6 w-full bg-slate-800 justify-center items-end pb-1.5 shrink-0 z-50">
          <div className="w-24 h-4 bg-slate-900 rounded-b-xl"></div>
        </div>

        {/* Screen Content Area */}
        <div className="flex-1 w-full bg-[#f8fafc] text-slate-900 relative overflow-hidden">
          {/* View 1: Watchlist */}
          <div 
            className={`absolute inset-0 transition-transform duration-300 ease-in-out ${
              selectedStock ? '-translate-x-full opacity-50' : 'translate-x-0 opacity-100'
            }`}
          >
            <Watchlist onSelectStock={setSelectedStock} />
          </div>

          {/* View 2: Stock Detail */}
          <div 
            className={`absolute inset-0 transition-transform duration-300 ease-in-out bg-[#f8fafc] ${
              selectedStock ? 'translate-x-0' : 'translate-x-full'
            }`}
          >
            {selectedStock && (
              <StockDetail 
                stock={selectedStock} 
                onBack={() => setSelectedStock(null)} 
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
