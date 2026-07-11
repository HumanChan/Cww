import 'stock.dart';

class MarketIndexSnapshot {
  const MarketIndexSnapshot({
    required this.index,
    this.advancing,
    this.declining,
    this.unchanged,
    this.limitUp,
    this.limitDown,
    this.tradingDate,
    this.updatedAt,
    this.isAvailable = true,
    this.isStale = false,
  });

  final Stock index;
  final int? advancing;
  final int? declining;
  final int? unchanged;
  final int? limitUp;
  final int? limitDown;
  final DateTime? tradingDate;
  final DateTime? updatedAt;
  final bool isAvailable;
  final bool isStale;

  bool get hasBreadth =>
      advancing != null && declining != null && unchanged != null;

  MarketIndexSnapshot copyWith({
    Stock? index,
    int? advancing,
    int? declining,
    int? unchanged,
    int? limitUp,
    int? limitDown,
    DateTime? tradingDate,
    DateTime? updatedAt,
    bool? isAvailable,
    bool? isStale,
  }) {
    return MarketIndexSnapshot(
      index: index ?? this.index,
      advancing: advancing ?? this.advancing,
      declining: declining ?? this.declining,
      unchanged: unchanged ?? this.unchanged,
      limitUp: limitUp ?? this.limitUp,
      limitDown: limitDown ?? this.limitDown,
      tradingDate: tradingDate ?? this.tradingDate,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      isStale: isStale ?? this.isStale,
    );
  }
}

class MarketLimitStats {
  const MarketLimitStats({this.limitUp, this.limitDown});

  final int? limitUp;
  final int? limitDown;

  bool get hasData => limitUp != null || limitDown != null;
}
