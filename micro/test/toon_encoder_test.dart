import 'package:flutter_test/flutter_test.dart';
import 'package:micro/infrastructure/serialization/toon_encoder.dart';

void main() {
  group('TOON Encoder', () {
    test('Simple object with primitives', () {
      final data = {'id': 123, 'name': 'Ada', 'active': true};

      final result = toonEncode(data);

      expect(result, contains('id: 123'));
      expect(result, contains('name: Ada'));
      expect(result, contains('active: true'));
    });

    test('Tabular array of objects', () {
      final data = {
        'items': [
          {'sku': 'A1', 'qty': 2, 'price': 9.99},
          {'sku': 'B2', 'qty': 1, 'price': 14.5},
        ],
      };

      final result = toonEncode(data);

      print('Tabular result:\n$result');
      expect(result, contains('[2]{sku,qty,price}:'));
      expect(result, contains('A1,2,9.99'));
      expect(result, contains('B2,1,14.5'));
    });

    test('Primitive array', () {
      final data = {
        'tags': ['foo', 'bar', 'baz'],
      };

      final result = toonEncode(data);

      print('Primitive array:\n$result');
      expect(result, contains('[3]: foo,bar,baz'));
    });

    test('Nested objects', () {
      final data = {
        'user': {
          'id': 1,
          'profile': {'name': 'Alice', 'email': 'alice@example.com'},
        },
      };

      final result = toonEncode(data);

      print('Nested:\n$result');
      expect(result, contains('user:'));
      expect(result, contains('  id: 1'));
      expect(result, contains('  profile:'));
      expect(result, contains('    name: Alice'));
    });

    test('Empty containers', () {
      expect(toonEncode(<String, dynamic>{}), equals(''));
      expect(toonEncode({'items': <dynamic>[]}), equals('items[0]:'));
      expect(toonEncode({'config': <String, dynamic>{}}), equals('config:'));
    });

    test('String quoting', () {
      final data = {
        'plain': 'hello',
        'withComma': 'a,b,c',
        'numeric': '42',
        'boolean': 'true',
        'empty': '',
      };

      final result = toonEncode(data);

      print('String quoting:\n$result');
      expect(result, contains('plain: hello')); // No quotes
      expect(result, contains('withComma: "a,b,c"')); // Quoted
      expect(result, contains('numeric: "42"')); // Quoted
      expect(result, contains('boolean: "true"')); // Quoted
      expect(result, contains('empty: ""')); // Quoted
    });

    test('Null values in table', () {
      final data = {
        'products': [
          {'sku': 'A1', 'stock': 50},
          {'sku': 'A2', 'stock': null},
        ],
      };

      final result = toonEncode(data);

      print('Nulls in table:\n$result');
      expect(result, contains('A1,50'));
      expect(result, contains('A2,')); // Empty cell for null
    });

    test('Length marker option', () {
      final data = {
        'tags': ['a', 'b', 'c'],
      };

      final result = toonEncode(data, lengthMarker: true);

      print('Length marker:\n$result');
      expect(result, contains('[#3]: a,b,c'));
    });

    test('Custom delimiter (tab)', () {
      final data = {
        'items': [
          {'id': 1, 'name': 'First'},
          {'id': 2, 'name': 'Second'},
        ],
      };

      final result = toonEncode(data, delimiter: '\t');

      print('Tab delimiter:\n$result');
      expect(result, contains('[2]{id\tname}'));
      expect(result, contains('1\tFirst'));
    });

    test('Mixed array (non-uniform)', () {
      final data = {
        'items': [
          42,
          {'key': 'value'},
          'text',
        ],
      };

      final result = toonEncode(data);

      print('Mixed array:\n$result');
      expect(result, contains('[3]:'));
      expect(result, contains('- 42'));
      expect(result, contains('- key: value'));
      expect(result, contains('- text'));
    });

    test('Real-world blackboard example', () {
      final blackboard = {
        'facts': [
          {
            'key': 'sentiment',
            'value': 'positive',
            'author': 'nlp_specialist',
            'confidence': 0.85,
          },
          {
            'key': 'rating',
            'value': 4.5,
            'author': 'math_specialist',
            'confidence': 1.0,
          },
          {
            'key': 'count',
            'value': 42,
            'author': 'stats_specialist',
            'confidence': 1.0,
          },
        ],
      };

      final result = toonEncode(blackboard);

      print('\nBlackboard TOON:\n$result\n');
      expect(result, contains('[3]{key,value,author,confidence}:'));
      expect(result, contains('sentiment,positive,nlp_specialist,0.85'));
      expect(result, contains('rating,4.5,math_specialist,1'));
      expect(result, contains('count,42,stats_specialist,1'));
    });
  });
}
