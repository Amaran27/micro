import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

/// Test to validate TOON format token efficiency vs JSON
/// Note: Actual LLM comprehension tests require API keys and network access
/// Run these manually with: flutter test test/toon_comprehension_test.dart
void main() {
  group('TOON vs JSON Token Efficiency Analysis', () {
    test('Size comparison - simple tabular data', () {
      final data = [
        {'id': 1, 'name': 'Alice', 'active': true},
        {'id': 2, 'name': 'Bob', 'active': false},
        {'id': 3, 'name': 'Charlie', 'active': true},
      ];

      final jsonStr = jsonEncode({'users': data});

      // Simulated TOON encoding
      final toonStr = '''users[3]{id,name,active}:
  1,Alice,true
  2,Bob,false
  3,Charlie,true''';

      print('\n=== Simple Tabular Data ===');
      print('JSON: $jsonStr');
      print('JSON Length: ${jsonStr.length} chars');
      print('\nTOON: $toonStr');
      print('TOON Length: ${toonStr.length} chars');

      final reduction =
          ((jsonStr.length - toonStr.length) / jsonStr.length * 100)
              .toStringAsFixed(1);
      print('Reduction: $reduction%');

      expect(toonStr.length, lessThan(jsonStr.length));
    });

    test('Size comparison - nested data', () {
      final data = {
        'order': {
          'id': 'ORD-123',
          'customer': {'name': 'Jane Doe', 'email': 'jane@example.com'},
          'items': [
            {'sku': 'A1', 'qty': 2, 'price': 9.99},
            {'sku': 'B2', 'qty': 1, 'price': 14.50},
          ],
          'total': 34.48,
        },
      };

      final jsonStr = jsonEncode(data);

      final toonStr = '''order:
  id: ORD-123
  customer:
    name: Jane Doe
    email: jane@example.com
  items[2]{sku,qty,price}:
    A1,2,9.99
    B2,1,14.5
  total: 34.48''';

      print('\n=== Nested Object Data ===');
      print('JSON Length: ${jsonStr.length} chars');
      print('TOON Length: ${toonStr.length} chars');

      final reduction =
          ((jsonStr.length - toonStr.length) / jsonStr.length * 100)
              .toStringAsFixed(1);
      print('Reduction: $reduction%');

      expect(toonStr.length, lessThan(jsonStr.length));
    });

    test('Token estimation - large dataset', () {
      final data = List.generate(
        10,
        (i) => {
          'id': i + 1,
          'name': 'User ${i + 1}',
          'email': 'user${i + 1}@example.com',
          'active': i % 2 == 0,
        },
      );

      final jsonStr = jsonEncode({'users': data});

      // Simulate TOON encoding (manual for now)
      final toonStr = '''
users[10]{id,name,email,active}:
  1,User 1,user1@example.com,true
  2,User 2,user2@example.com,false
  3,User 3,user3@example.com,true
  4,User 4,user4@example.com,false
  5,User 5,user5@example.com,true
  6,User 6,user6@example.com,false
  7,User 7,user7@example.com,true
  8,User 8,user8@example.com,false
  9,User 9,user9@example.com,true
  10,User 10,user10@example.com,false
''';

      print('JSON Length: ${jsonStr.length} chars');
      print('TOON Length: ${toonStr.length} chars');

      // Rough token estimation: ~4 chars per token for English
      final jsonTokens = (jsonStr.length / 4).ceil();
      final toonTokens = (toonStr.length / 4).ceil();

      print('JSON Estimated Tokens: $jsonTokens');
      print('TOON Estimated Tokens: $toonTokens');
      print(
        'Token Reduction: ${((jsonTokens - toonTokens) / jsonTokens * 100).toStringAsFixed(1)}%',
      );

      expect(
        toonTokens,
        lessThan(jsonTokens),
        reason: 'TOON should use fewer tokens than JSON',
      );
    });
  });
}
