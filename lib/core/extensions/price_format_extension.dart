import 'package:intl/intl.dart';

final _twdFormat = NumberFormat.currency(
  locale: 'zh_TW',
  symbol: r'NT$',
  decimalDigits: 0,
);

extension PriceFormat on num {
  String get asTwd => _twdFormat.format(this);
}
