enum StockType {
  stock,
  crypto,
}

enum Market {
  cn,
  hk,
  us,
  kr,
  tw,
  jp,
  other,
}

class Stock {
  const Stock({
    required this.code,
    required this.name,
    required this.secid,
    this.market = Market.cn,
    this.type = StockType.stock,
    this.price,
    this.change,
    this.percent,
    this.high,
    this.low,
    this.open,
    this.preClose,
    this.amount,
    this.volume,
    this.turnoverRate,
    this.peDynamic,
    this.peStatic,
    this.peTTM,
    this.pb,
    this.marketCap,
    this.volumeRatio,
    this.marketDepth = const MarketDepth(),
  });

  final String code;
  final String name;
  final String secid;
  final Market market;
  final StockType type;
  final double? price;
  final double? change;
  final double? percent;
  final double? high;
  final double? low;
  final double? open;
  final double? preClose;
  final double? amount;
  final double? volume;
  final double? turnoverRate;
  final double? peDynamic;
  final double? peStatic;
  final double? peTTM;
  final double? pb;
  final double? marketCap;
  final double? volumeRatio;
  final MarketDepth marketDepth;

  bool get isUp => (percent ?? 0) >= 0;
  bool get hasMarketDepth => marketDepth.hasData;

  Stock copyWith({
    String? code,
    String? name,
    String? secid,
    Market? market,
    StockType? type,
    double? price,
    double? change,
    double? percent,
    double? high,
    double? low,
    double? open,
    double? preClose,
    double? amount,
    double? volume,
    double? turnoverRate,
    double? peDynamic,
    double? peStatic,
    double? peTTM,
    double? pb,
    double? marketCap,
    double? volumeRatio,
    MarketDepth? marketDepth,
  }) {
    return Stock(
      code: code ?? this.code,
      name: name ?? this.name,
      secid: secid ?? this.secid,
      market: market ?? this.market,
      type: type ?? this.type,
      price: price ?? this.price,
      change: change ?? this.change,
      percent: percent ?? this.percent,
      high: high ?? this.high,
      low: low ?? this.low,
      open: open ?? this.open,
      preClose: preClose ?? this.preClose,
      amount: amount ?? this.amount,
      volume: volume ?? this.volume,
      turnoverRate: turnoverRate ?? this.turnoverRate,
      peDynamic: peDynamic ?? this.peDynamic,
      peStatic: peStatic ?? this.peStatic,
      peTTM: peTTM ?? this.peTTM,
      pb: pb ?? this.pb,
      marketCap: marketCap ?? this.marketCap,
      volumeRatio: volumeRatio ?? this.volumeRatio,
      marketDepth: marketDepth ?? this.marketDepth,
    );
  }

  Stock mergeQuote(Stock quote) {
    return copyWith(
      name: quote.name.isEmpty ? name : quote.name,
      secid: quote.secid.isEmpty ? secid : quote.secid,
      market: quote.market,
      type: quote.type,
      price: quote.price,
      change: quote.change,
      percent: quote.percent,
      high: quote.high,
      low: quote.low,
      open: quote.open,
      preClose: quote.preClose,
      amount: quote.amount,
      volume: quote.volume,
      turnoverRate: quote.turnoverRate,
      peDynamic: quote.peDynamic,
      peStatic: quote.peStatic,
      peTTM: quote.peTTM,
      pb: quote.pb,
      marketCap: quote.marketCap,
      volumeRatio: quote.volumeRatio,
      marketDepth: quote.marketDepth.hasData ? quote.marketDepth : marketDepth,
    );
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      secid: json['secid'] as String? ?? '',
      market: _marketFromString(json['market'] as String?),
      type: _typeFromString(json['type'] as String?),
      price: _num(json['price']),
      change: _num(json['change']),
      percent: _num(json['percent']),
      high: _num(json['high']),
      low: _num(json['low']),
      open: _num(json['open']),
      preClose: _num(json['preClose']),
      amount: _num(json['amount']),
      volume: _num(json['volume']),
      turnoverRate: _num(json['turnoverRate']),
      peDynamic: _num(json['peDynamic']),
      peStatic: _num(json['peStatic']),
      peTTM: _num(json['peTTM']),
      pb: _num(json['pb']),
      marketCap: _num(json['marketCap']),
      volumeRatio: _num(json['volumeRatio']),
      marketDepth: MarketDepth.fromJson(json['marketDepth']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'secid': secid,
      'market': market.name.toUpperCase(),
      'type': type.name,
      'price': price,
      'change': change,
      'percent': percent,
      'high': high,
      'low': low,
      'open': open,
      'preClose': preClose,
      'amount': amount,
      'volume': volume,
      'turnoverRate': turnoverRate,
      'peDynamic': peDynamic,
      'peStatic': peStatic,
      'peTTM': peTTM,
      'pb': pb,
      'marketCap': marketCap,
      'volumeRatio': volumeRatio,
      if (marketDepth.hasData) 'marketDepth': marketDepth.toJson(),
    };
  }
}

class MarketDepth {
  const MarketDepth({
    this.bids = const [],
    this.asks = const [],
    this.isFullDepth = false,
    this.updatedAt,
  });

  final List<MarketDepthLevel> bids;
  final List<MarketDepthLevel> asks;
  final bool isFullDepth;
  final DateTime? updatedAt;

  bool get hasData => bids.isNotEmpty || asks.isNotEmpty;

  factory MarketDepth.bestQuote({
    double? bidPrice,
    double? bidVolume,
    double? askPrice,
    double? askVolume,
    DateTime? updatedAt,
  }) {
    return MarketDepth(
      bids: _levelList(bidPrice, bidVolume),
      asks: _levelList(askPrice, askVolume),
      updatedAt: updatedAt,
    );
  }

  factory MarketDepth.fromJson(Object? raw) {
    if (raw is! Map) return const MarketDepth();
    final json = Map<String, dynamic>.from(raw);
    return MarketDepth(
      bids: _depthFromJson(json['bids']),
      asks: _depthFromJson(json['asks']),
      isFullDepth: json['isFullDepth'] == true,
      updatedAt: _date(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bids.isNotEmpty) 'bids': bids.map((level) => level.toJson()).toList(),
      if (asks.isNotEmpty) 'asks': asks.map((level) => level.toJson()).toList(),
      'isFullDepth': isFullDepth,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

class MarketDepthLevel {
  const MarketDepthLevel({
    required this.price,
    this.volume,
  });

  final double price;
  final double? volume;

  factory MarketDepthLevel.fromJson(Map<String, dynamic> json) {
    return MarketDepthLevel(
      price: _num(json['price']) ?? 0,
      volume: _num(json['volume']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      if (volume != null) 'volume': volume,
    };
  }
}

double? _num(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

List<MarketDepthLevel> _levelList(double? price, double? volume) {
  if (price == null || price <= 0) return const [];
  return [MarketDepthLevel(price: price, volume: volume)];
}

List<MarketDepthLevel> _depthFromJson(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => MarketDepthLevel.fromJson(Map<String, dynamic>.from(item)))
      .where((level) => level.price > 0)
      .toList();
}

StockType _typeFromString(String? raw) {
  return raw == StockType.crypto.name ? StockType.crypto : StockType.stock;
}

Market _marketFromString(String? raw) {
  return switch (raw?.toUpperCase()) {
    'HK' => Market.hk,
    'US' => Market.us,
    'KR' => Market.kr,
    'TW' => Market.tw,
    'JP' => Market.jp,
    'OTHER' => Market.other,
    _ => Market.cn,
  };
}
