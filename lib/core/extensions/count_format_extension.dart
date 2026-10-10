import 'package:intl/intl.dart';

final _countFormat = NumberFormat.decimalPattern('zh_TW');

extension CountFormat on int {
  String get asCount => _countFormat.format(this);
}
