/// TOON (Token-Oriented Object Notation) Encoder for Dart/Flutter
///
/// Reduces token count by 30-60% vs JSON for structured data.
/// Use for INPUT serialization to LLMs (blackboard state, tool schemas).
/// Do NOT use for LLM output - request JSON for reliability.
///
/// Based on: https://github.com/johannschopplich/toon
library toon_encoder;

class TOONEncoder {
  final String delimiter;
  final int indent;
  final bool lengthMarker;

  TOONEncoder({
    this.delimiter = ',',
    this.indent = 2,
    this.lengthMarker = false,
  });

  /// Encode any JSON-serializable value to TOON format
  String encode(dynamic value) {
    final buffer = StringBuffer();
    _encodeValue(value, buffer, 0);
    return buffer.toString().trimRight();
  }

  void _encodeValue(dynamic value, StringBuffer buffer, int depth) {
    if (value == null) {
      buffer.write('null');
    } else if (value is bool) {
      buffer.write(value ? 'true' : 'false');
    } else if (value is num) {
      buffer.write(_formatNumber(value));
    } else if (value is String) {
      buffer.write(_formatString(value));
    } else if (value is List) {
      _encodeArray(value, buffer, depth);
    } else if (value is Map) {
      _encodeObject(value as Map<String, dynamic>, buffer, depth);
    } else {
      // Fallback for unsupported types
      buffer.write('null');
    }
  }

  void _encodeObject(Map<String, dynamic> obj, StringBuffer buffer, int depth) {
    if (obj.isEmpty) {
      return; // Empty object produces no output
    }

    final keys = obj.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      if (i > 0) buffer.write('\n');

      final key = keys[i];
      final value = obj[key];

      buffer.write('${_indentStr(depth)}$key');

      if (value is Map && (value as Map).isNotEmpty) {
        buffer.write(':\n');
        _encodeObject(value as Map<String, dynamic>, buffer, depth + 1);
      } else if (value is List) {
        final list = value as List;
        if (list.isEmpty) {
          buffer.write('[0]:');
        } else if (_isTabularArray(list)) {
          _encodeTabularArray(list, buffer, depth + 1);
        } else if (_isPrimitiveArray(list)) {
          _encodePrimitiveArray(list, buffer);
        } else {
          _encodeListArray(list, buffer, depth + 1);
        }
      } else {
        buffer.write(': ');
        _encodeValue(value, buffer, depth);
      }
    }
  }

  void _encodeArray(List arr, StringBuffer buffer, int depth) {
    if (arr.isEmpty) {
      buffer.write('[0]:');
      return;
    }

    if (_isTabularArray(arr)) {
      _encodeTabularArray(arr, buffer, depth);
    } else if (_isPrimitiveArray(arr)) {
      _encodePrimitiveArray(arr, buffer);
    } else {
      _encodeListArray(arr, buffer, depth);
    }
  }

  void _encodeTabularArray(List arr, StringBuffer buffer, int depth) {
    // Format: [3]{id,name,price}:
    //           1,Alice,9.99
    //           2,Bob,14.5
    final first = arr[0] as Map<String, dynamic>;
    final keys = first.keys.toList();

    final lengthPrefix = lengthMarker ? '#' : '';
    buffer.write('[$lengthPrefix${arr.length}]{${keys.join(delimiter)}}:\n');

    for (final item in arr) {
      buffer.write(_indentStr(depth));
      final row = <String>[];
      for (final key in keys) {
        final value = (item as Map<String, dynamic>)[key];
        row.add(_formatCellValue(value));
      }
      buffer.write(row.join(delimiter));
      if (item != arr.last) buffer.write('\n');
    }
  }

  void _encodePrimitiveArray(List arr, StringBuffer buffer) {
    // Format: [3]: foo,bar,baz
    final lengthPrefix = lengthMarker ? '#' : '';
    buffer.write('[$lengthPrefix${arr.length}]: ');
    buffer.write(arr.map((v) => _formatCellValue(v)).join(delimiter));
  }

  void _encodeListArray(List arr, StringBuffer buffer, int depth) {
    // Format (mixed/non-uniform):
    // items[3]:
    //   - value1
    //   - key: value2
    final lengthPrefix = lengthMarker ? '#' : '';
    buffer.write('[$lengthPrefix${arr.length}]:\n');

    for (final item in arr) {
      buffer.write(_indentStr(depth));
      buffer.write('- ');

      if (item is Map && item.isNotEmpty) {
        final map = item as Map<String, dynamic>;
        final firstKey = map.keys.first;
        buffer.write('$firstKey: ');
        _encodeValue(map[firstKey], buffer, depth);

        if (map.length > 1) {
          buffer.write('\n');
          final remaining = Map<String, dynamic>.from(map)..remove(firstKey);
          for (final key in remaining.keys) {
            buffer.write('${_indentStr(depth + 1)}$key: ');
            _encodeValue(remaining[key], buffer, depth + 1);
            if (key != remaining.keys.last) buffer.write('\n');
          }
        }
      } else if (item is List) {
        _encodeArray(item, buffer, depth + 1);
      } else {
        _encodeValue(item, buffer, depth);
      }

      if (item != arr.last) buffer.write('\n');
    }
  }

  bool _isTabularArray(List arr) {
    if (arr.isEmpty) return false;
    if (arr.first is! Map) return false;

    final firstMap = arr.first as Map<String, dynamic>;
    final keys = firstMap.keys.toSet();

    // All items must be maps with same keys and primitive values
    for (final item in arr) {
      if (item is! Map) return false;
      final itemMap = item as Map<String, dynamic>;
      if (!keys.containsAll(itemMap.keys) ||
          !itemMap.keys.toSet().containsAll(keys)) {
        return false;
      }
      // Check all values are primitives
      if (itemMap.values.any((v) => v is Map || v is List)) {
        return false;
      }
    }

    return true;
  }

  bool _isPrimitiveArray(List arr) {
    return arr.every((item) => item is! Map && item is! List);
  }

  String _formatNumber(num value) {
    if (value is int) return value.toString();

    // Remove unnecessary decimals
    final str = value.toString();
    if (str.contains('.') && double.parse(str) == value.toInt()) {
      return value.toInt().toString();
    }
    return str;
  }

  String _formatString(String value) {
    // Quote if:
    // - Looks like number/boolean
    // - Contains delimiter, colon, brackets, or hyphen at start
    // - Has leading/trailing whitespace
    // - Contains newlines or quotes
    // - Is empty

    if (value.isEmpty) return '""';
    if (value.trim() != value) return '"${_escape(value)}"';
    if (value == 'true' || value == 'false' || value == 'null') {
      return '"$value"';
    }
    if (num.tryParse(value) != null) return '"$value"';
    if (value.contains(delimiter) ||
        value.contains(':') ||
        value.contains('[') ||
        value.contains(']') ||
        value.contains('{') ||
        value.contains('}') ||
        value.startsWith('-') ||
        value.contains('\n') ||
        value.contains('"')) {
      return '"${_escape(value)}"';
    }

    return value;
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return _formatNumber(value);
    if (value is String) {
      // In tables, empty strings are just empty
      if (value.isEmpty) return '';
      // Quote if contains delimiter or special chars
      if (value.contains(delimiter) ||
          value.contains('\n') ||
          value.contains('"') ||
          value.trim() != value) {
        return '"${_escape(value)}"';
      }
      return value;
    }
    return value.toString();
  }

  String _escape(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  String _indentStr(int depth) {
    return ' ' * (depth * indent);
  }
}

/// Convenience function for quick encoding
String toonEncode(
  dynamic value, {
  String delimiter = ',',
  int indent = 2,
  bool lengthMarker = false,
}) {
  final encoder = TOONEncoder(
    delimiter: delimiter,
    indent: indent,
    lengthMarker: lengthMarker,
  );
  return encoder.encode(value);
}
