import 'package:intl/intl.dart';

final _percentFormat = NumberFormat.percentPattern('zh_TW');

extension PercentFormat on double {
  String get asPercent => _percentFormat.format(this);
}
