import 'package:flutter_test/flutter_test.dart';

import 'package:cww_flutter/src/features/market/domain/stock.dart';

void main() {
  test('盘口数据可以序列化并从报价合并', () {
    const cached = Stock(
      code: 'BTCUSDT',
      name: 'Bitcoin',
      secid: 'BTCUSDT',
      type: StockType.crypto,
      price: 100,
      marketDepth: MarketDepth(
        bids: [MarketDepthLevel(price: 99, volume: 2)],
        asks: [MarketDepthLevel(price: 101, volume: 3)],
        isFullDepth: true,
      ),
    );

    const quote = Stock(
      code: 'BTCUSDT',
      name: 'Bitcoin',
      secid: 'BTCUSDT',
      type: StockType.crypto,
      price: 102,
      marketDepth: MarketDepth(
        bids: [MarketDepthLevel(price: 101.9, volume: 1.2)],
        asks: [MarketDepthLevel(price: 102.1, volume: 1.4)],
        isFullDepth: true,
      ),
    );

    final merged = cached.mergeQuote(quote);
    final restored = Stock.fromJson(merged.toJson());

    expect(restored.price, 102);
    expect(restored.marketDepth.isFullDepth, isTrue);
    expect(restored.marketDepth.bids.single.price, 101.9);
    expect(restored.marketDepth.asks.single.volume, 1.4);
  });
}
