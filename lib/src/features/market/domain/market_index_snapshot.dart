import 'stock.dart';

class MarketIndexSnapshot {
  const MarketIndexSnapshot({
    required this.index,
    this.advancing,
    this.declining,
    this.unchanged,
    this.updatedAt,
    this.isAvailable = true,
    this.isStale = false,
  });

  final Stock index;
  final int? advancing;
  final int? declining;
  final int? unchanged;
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
    DateTime? updatedAt,
    bool? isAvailable,
    bool? isStale,
  }) {
    return MarketIndexSnapshot(
      index: index ?? this.index,
      advancing: advancing ?? this.advancing,
      declining: declining ?? this.declining,
      unchanged: unchanged ?? this.unchanged,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      isStale: isStale ?? this.isStale,
    );
  }
}
