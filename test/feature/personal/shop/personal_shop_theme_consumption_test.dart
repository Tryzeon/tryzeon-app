import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('personal shop presentation avoids hardcoded shared style definitions', () {
    final files = Directory('lib/feature/personal/shop/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((final file) {
          return file.path.endsWith('.dart');
        });

    const bannedPatterns = <String>[
      'Colors.black',
      'Colors.white',
      'Colors.green',
      'Colors.amber',
      'Colors.red',
      'const TextStyle(',
      'TextStyle(',
      'fontWeight:',
      'fontSize:',
      'letterSpacing:',
      'BoxShadow(',
      'BorderRadius.circular(',
      'Radius.circular(',
    ];

    final violations = <String>[];

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final pattern in bannedPatterns) {
        if (source.contains(pattern)) {
          violations.add('${file.path}: $pattern');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
