import 'dart:convert';

/// Represents different types of messages that can be sent/received
enum MessageType {
  plan,
  stepExecution,
  verification,
  error,
  streamStart,
  streamEnd,
  heartbeat,
}

/// Base class for all serializable messages
class SerializableMessage {
  final String id;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  SerializableMessage({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.payload,
  });

  factory SerializableMessage.fromJson(Map<String, dynamic> json) {
    return SerializableMessage(
      id: json['id'] as String,
      type: MessageTypeExtension.fromJson(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      payload: json['payload'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'payload': payload,
  };

  @override
  String toString() =>
      'SerializableMessage(id: $id, type: $type, timestamp: $timestamp)';
}

/// Serializes and deserializes messages for WebSocket communication
class MessageSerializer {
  /// Encode a message to JSON string
  static String encode(SerializableMessage message) {
    try {
      final json = message.toJson();
      return jsonEncode(json);
    } catch (e) {
      throw MessageSerializationError(
        'Failed to encode message: $e',
        originalError: e,
      );
    }
  }

  /// Decode a JSON string to a message
  static SerializableMessage decode(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SerializableMessage.fromJson(json);
    } catch (e) {
      throw MessageSerializationError(
        'Failed to decode message: $e',
        originalError: e,
      );
    }
  }

  /// Encode message to raw format (for WebSocket sink)
  static dynamic encodeForWebSocket(SerializableMessage message) {
    try {
      return encode(message);
    } catch (e) {
      throw MessageSerializationError(
        'Failed to encode for WebSocket: $e',
        originalError: e,
      );
    }
  }

  /// Decode message from raw WebSocket format
  static SerializableMessage decodeFromWebSocket(dynamic rawData) {
    try {
      if (rawData is String) {
        return decode(rawData);
      } else if (rawData is List<int>) {
        return decode(utf8.decode(rawData));
      } else {
        throw MessageSerializationError(
          'Unsupported WebSocket data type: ${rawData.runtimeType}',
        );
      }
    } catch (e) {
      if (e is MessageSerializationError) rethrow;
      throw MessageSerializationError(
        'Failed to decode from WebSocket: $e',
        originalError: e,
      );
    }
  }

  /// Create a heartbeat message
  static SerializableMessage createHeartbeat({required String clientId}) {
    return SerializableMessage(
      id: clientId,
      type: MessageType.heartbeat,
      timestamp: DateTime.now(),
      payload: {'clientId': clientId},
    );
  }

  /// Create a plan message
  static SerializableMessage createPlanMessage({
    required String id,
    required Map<String, dynamic> plan,
  }) {
    return SerializableMessage(
      id: id,
      type: MessageType.plan,
      timestamp: DateTime.now(),
      payload: plan,
    );
  }

  /// Create a step execution message
  static SerializableMessage createStepExecutionMessage({
    required String id,
    required int stepNumber,
    required String stepName,
    required Map<String, dynamic> stepData,
  }) {
    return SerializableMessage(
      id: id,
      type: MessageType.stepExecution,
      timestamp: DateTime.now(),
      payload: {
        'stepNumber': stepNumber,
        'stepName': stepName,
        'stepData': stepData,
      },
    );
  }

  /// Create a verification message
  static SerializableMessage createVerificationMessage({
    required String id,
    required bool success,
    required String message,
    Map<String, dynamic>? details,
  }) {
    return SerializableMessage(
      id: id,
      type: MessageType.verification,
      timestamp: DateTime.now(),
      payload: {
        'success': success,
        'message': message,
        if (details != null) 'details': details,
      },
    );
  }

  /// Create an error message
  static SerializableMessage createErrorMessage({
    required String id,
    required String errorMessage,
    String? errorCode,
    Map<String, dynamic>? details,
  }) {
    return SerializableMessage(
      id: id,
      type: MessageType.error,
      timestamp: DateTime.now(),
      payload: {
        'message': errorMessage,
        if (errorCode != null) 'code': errorCode,
        if (details != null) 'details': details,
      },
    );
  }

  /// Create a stream start message
  static SerializableMessage createStreamStartMessage({required String id}) {
    return SerializableMessage(
      id: id,
      type: MessageType.streamStart,
      timestamp: DateTime.now(),
      payload: {},
    );
  }

  /// Create a stream end message
  static SerializableMessage createStreamEndMessage({required String id}) {
    return SerializableMessage(
      id: id,
      type: MessageType.streamEnd,
      timestamp: DateTime.now(),
      payload: {},
    );
  }
}

/// Custom exception for message serialization errors
class MessageSerializationError implements Exception {
  final String message;
  final dynamic originalError;

  MessageSerializationError(this.message, {this.originalError});

  @override
  String toString() => 'MessageSerializationError: $message';
}

/// Extension to parse MessageType from JSON
extension MessageTypeExtension on MessageType {
  static MessageType fromJson(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.error,
    );
  }

  String toJson() => name;
}
