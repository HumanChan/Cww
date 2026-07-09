import 'package:intl/intl.dart';

import '../../features/market/domain/stock.dart';

String formatSignedPercent(double? percent) {
  if (percent == null) return '--';
  final sign = percent > 0 ? '+' : '';
  return '$sign${percent.toStringAsFixed(2)}%';
}

String formatPrice(
  double? value, {
  StockType type = StockType.stock,
  String symbol = '',
}) {
  if (value == null || value.isNaN) return '--';
  final decimals = type == StockType.crypto && value.abs() < 1 ? 4 : 2;
  return '$symbol${value.toStringAsFixed(decimals)}';
}

String formatAmount(double? amount, {StockType type = StockType.stock}) {
  if (amount == null || amount.isNaN) return '--';
  if (type == StockType.crypto) {
    if (amount >= 1000000000000) {
      return '${(amount / 1000000000000).toStringAsFixed(2)}T';
    }
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(2)}B';
    }
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(2)}K';
    return amount.toStringAsFixed(0);
  }
  if (amount >= 1000000000000) {
    return '${(amount / 1000000000000).toStringAsFixed(2)}万亿';
  }
  if (amount >= 100000000) {
    return '${(amount / 100000000).toStringAsFixed(2)}亿';
  }
  if (amount >= 10000) return '${(amount / 10000).toStringAsFixed(2)}万';
  return amount.toStringAsFixed(0);
}

String formatVolume(double? volume) {
  if (volume == null || volume.isNaN) return '--';
  return NumberFormat.compact(locale: 'zh_CN').format(volume);
}

String marketDisplayName(Stock stock) {
  if (stock.type == StockType.crypto) return 'Crypto';
  switch (stock.market) {
    case Market.hk:
      return '港股';
    case Market.us:
      return '美股';
    case Market.kr:
      return '韩股';
    case Market.tw:
      return '台股';
    case Market.jp:
      return '日股';
    case Market.cn:
      if (stock.code.startsWith('6')) return '沪市';
      if (stock.code.startsWith('0') || stock.code.startsWith('3')) return '深市';
      return 'A股';
    case Market.other:
      return '其他';
  }
}

String currencySymbol(Stock stock) {
  if (stock.type == StockType.crypto) return r'$';
  switch (stock.market) {
    case Market.hk:
      return 'HK\$';
    case Market.us:
      return r'$';
    case Market.kr:
      return '₩';
    case Market.tw:
      return 'NT\$';
    case Market.jp:
      return '¥';
    case Market.cn:
    case Market.other:
      return '¥';
  }
}
