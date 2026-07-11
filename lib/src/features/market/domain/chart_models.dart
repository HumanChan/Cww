enum ChartType {
  intraday,
  dayK,
  weekK,
  monthK,
}

extension ChartTypeLabel on ChartType {
  String get label {
    return switch (this) {
      ChartType.intraday => '分时',
      ChartType.dayK => '日K',
      ChartType.weekK => '周K',
      ChartType.monthK => '月K',
    };
  }
}

class ChartPoint {
  const ChartPoint({
    required this.time,
    required this.price,
    this.avg,
    this.leading,
    this.volume,
  });

  final String time;
  final double price;
  final double? avg;
  final double? leading;
  final double? volume;
}

class KLinePoint {
  const KLinePoint({
    required this.date,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.volume,
  });

  final String date;
  final double open;
  final double close;
  final double high;
  final double low;
  final double volume;
}

class ChartData {
  const ChartData({
    required this.type,
    this.intraday = const [],
    this.kLine = const [],
  });

  final ChartType type;
  final List<ChartPoint> intraday;
  final List<KLinePoint> kLine;
}
