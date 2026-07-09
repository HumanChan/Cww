import 'stock.dart';

class StockGroup {
  const StockGroup({
    required this.id,
    required this.name,
    required this.stocks,
  });

  final String id;
  final String name;
  final List<Stock> stocks;

  StockGroup copyWith({
    String? id,
    String? name,
    List<Stock>? stocks,
  }) {
    return StockGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      stocks: stocks ?? this.stocks,
    );
  }

  factory StockGroup.fromJson(Map<String, dynamic> json) {
    return StockGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      stocks: (json['stocks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Stock.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stocks': stocks.map((stock) => stock.toJson()).toList(),
    };
  }
}
