import 'package:intl/intl.dart';

final _dateFormat = DateFormat('yyyy/MM/dd');

extension DateFormatExtension on DateTime {
  String get asDate => _dateFormat.format(toLocal());
}
