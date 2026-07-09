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

  bool get isUp => (percent ?? 0) >= 0;

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
    };
  }
}

double? _num(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
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
