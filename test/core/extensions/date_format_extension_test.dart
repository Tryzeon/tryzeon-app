import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/extensions/date_format_extension.dart';

void main() {
  test('formats the local calendar date of a UTC instant', () {
    final justAfterLocalMidnight = DateTime(2026, 10, 18, 0, 30).toUtc();

    expect(justAfterLocalMidnight.asDate, '2026/10/18');
  });

  test('pads month and day', () {
    expect(DateTime(2026, 3, 5).asDate, '2026/03/05');
  });
}
