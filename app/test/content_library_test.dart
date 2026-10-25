import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/content_library.dart';

import 'store_test.dart' show fixture;

void main() {
  test('B02 content rejects every duplicated ID for the whole load, regardless of count/order', () {
    final a = jsonEncode(fixture().toJson());
    final b = jsonEncode(fixture().toJson()..['content_version'] = 2);
    final other = jsonEncode(fixture(12).toJson());
    for (final sources in [
      [a, a, other],
      [a, b, a, other],
      [b, other, a, b],
      [other, a, b, a, b],
    ]) {
      final definitions = parsePuzzleDefinitions(sources);
      expect(definitions.keys, ['main-012']);
      expect(definitions['main-012']!.mainLevel, 12);
    }
    expect(parsePuzzleDefinitions([a, '{bad', other]).keys, [
      'main-001',
      'main-012',
    ]);
  });
}
