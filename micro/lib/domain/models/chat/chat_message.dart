import '../autonomous/user_intent.dart';
import '../autonomous/autonomous_action.dart';
import '../../../infrastructure/mcp/core/models/tool_result.dart';

/// Message types for chat
enum MessageType {
  /// Regular text message from user
  user,

  /// Response from assistant
  assistant,

  /// System notification
  system,

  /// Tool execution result
  toolExecution,

  /// Autonomous action
  autonomousAction,

  /// Error message
  error,

  /// Typing indicator
  typing,
}

/// Message status for tracking
enum MessageStatus {
  /// Message is being sent
  sending,

  /// Message was sent successfully
  sent,

  /// Message failed to send
  failed,

  /// Message was delivered
  delivered,

  /// Message was read
  read,
}

/// Chat message model
class ChatMessage {
  final String id;
  final DateTime timestamp;
  final MessageType type;
  final String content;
  final MessageStatus status;
  final String? userId;
  final Map<String, dynamic> metadata;
  final UserIntent? recognizedIntent;
  final AutonomousAction? autonomousAction;
  final ToolResult? toolResult;
  final List<String> attachments;
  final bool isEdited;
  final DateTime? editedAt;
  final String? replyToId;
  final List<String> readBy;

  const ChatMessage({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.content,
    this.status = MessageStatus.sent,
    this.userId,
    this.metadata = const {},
    this.recognizedIntent,
    this.autonomousAction,
    this.toolResult,
    this.attachments = const [],
    this.isEdited = false,
    this.editedAt,
    this.replyToId,
    this.readBy = const [],
  });

  /// Create a user message
  factory ChatMessage.user({
    required String id,
    required String content,
    String? userId,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    String? replyToId,
  }) {
    return ChatMessage(
      id: id,
      timestamp: DateTime.now(),
      type: MessageType.user,
      content: content,
      status: MessageStatus.sending,
      userId: userId,
      metadata: metadata ?? {},
      attachments: attachments ?? [],
      replyToId: replyToId,
    );
  }

  /// Create an assistant message
  factory ChatMessage.assistant({
    required String id,
    required String content,
    String? userId,
    Map<String, dynamic>? metadata,
    UserIntent? recognizedIntent,
    String? replyToId,
  }) {
    return ChatMessage(
      id: id,
      timestamp: DateTime.now(),
      type: MessageType.assistant,
      content: content,
      status: MessageStatus.sent,
      userId: userId,
      metadata: metadata ?? {},
      recognizedIntent: recognizedIntent,
      replyToId: replyToId,
    );
  }

  /// Create a system message
  factory ChatMessage.system({
    required String id,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      timestamp: DateTime.now(),
      type: MessageType.system,
      content: content,
      status: MessageStatus.sent,
      metadata: metadata ?? {},
    );
  }

  /// Create a tool execution message
  factory ChatMessage.toolExecution({
    required String id,
    required String content,
    required ToolResult toolResult,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) {
    return ChatMessage(
      id: id,
      timestamp: DateTime.now(),
      type: MessageType.toolExecution,
      content: content,
      status: MessageStatus.sent,
      metadata: metadata ?? {},
      toolResult: toolResult,
      replyToId: replyToId,
    );
  }

  /// Create an autonomous action message
  factory ChatMessage.autonomousAction({
    required String id,
    required String content,
    required AutonomousAction action,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) {
    return ChatMessage(
      id: id,
      timestamp: DateTime.now(),
      type: MessageType.autonomousAction,
      content: content,
      status: MessageStatus.sent,
      metadata: metadata ?? {},
      autonomousAction: action,
      replyToId: replyToId,
    );
  }

  /// Create an error message
  factory ChatMessage.error({
    required String id,
    required String content,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) {
    return ChatMessage(
      id: id,
      timestamp: DateTime.now(),
      type: MessageType.error,
      content: content,
      status: MessageStatus.sent,
      metadata: metadata ?? {},
      replyToId: replyToId,
    );
  }

  /// Create a typing indicator message
  factory ChatMessage.typing({
    required String id,
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      timestamp: DateTime.now(),
      type: MessageType.typing,
      content: '...',
      status: MessageStatus.sent,
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Mark message as sent
  ChatMessage markAsSent() {
    return ChatMessage(
      id: id,
      timestamp: timestamp,
      type: type,
      content: content,
      status: MessageStatus.sent,
      userId: userId,
      metadata: metadata,
      recognizedIntent: recognizedIntent,
      autonomousAction: autonomousAction,
      toolResult: toolResult,
      attachments: attachments,
      isEdited: isEdited,
      editedAt: editedAt,
      replyToId: replyToId,
      readBy: readBy,
    );
  }

  /// Mark message as failed
  ChatMessage markAsFailed() {
    return ChatMessage(
      id: id,
      timestamp: timestamp,
      type: type,
      content: content,
      status: MessageStatus.failed,
      userId: userId,
      metadata: metadata,
      recognizedIntent: recognizedIntent,
      autonomousAction: autonomousAction,
      toolResult: toolResult,
      attachments: attachments,
      isEdited: isEdited,
      editedAt: editedAt,
      replyToId: replyToId,
      readBy: readBy,
    );
  }

  /// Mark message as delivered
  ChatMessage markAsDelivered() {
    return ChatMessage(
      id: id,
      timestamp: timestamp,
      type: type,
      content: content,
      status: MessageStatus.delivered,
      userId: userId,
      metadata: metadata,
      recognizedIntent: recognizedIntent,
      autonomousAction: autonomousAction,
      toolResult: toolResult,
      attachments: attachments,
      isEdited: isEdited,
      editedAt: editedAt,
      replyToId: replyToId,
      readBy: readBy,
    );
  }

  /// Mark message as read by user
  ChatMessage markAsRead(String userId) {
    final updatedReadBy = List<String>.from(readBy);
    if (!updatedReadBy.contains(userId)) {
      updatedReadBy.add(userId);
    }

    return ChatMessage(
      id: id,
      timestamp: timestamp,
      type: type,
      content: content,
      status: MessageStatus.read,
      userId: userId,
      metadata: metadata,
      recognizedIntent: recognizedIntent,
      autonomousAction: autonomousAction,
      toolResult: toolResult,
      attachments: attachments,
      isEdited: isEdited,
      editedAt: editedAt,
      replyToId: replyToId,
      readBy: updatedReadBy,
    );
  }

  /// Edit message content
  ChatMessage edit(String newContent) {
    return ChatMessage(
      id: id,
      timestamp: timestamp,
      type: type,
      content: newContent,
      status: status,
      userId: userId,
      metadata: metadata,
      recognizedIntent: recognizedIntent,
      autonomousAction: autonomousAction,
      toolResult: toolResult,
      attachments: attachments,
      isEdited: true,
      editedAt: DateTime.now(),
      replyToId: replyToId,
      readBy: readBy,
    );
  }

  /// Check if message is from user
  bool get isFromUser => type == MessageType.user;

  /// Check if message is from assistant
  bool get isFromAssistant => type == MessageType.assistant;

  /// Check if message is a system message
  bool get isSystemMessage => type == MessageType.system;

  /// Check if message is a tool execution
  bool get isToolExecution => type == MessageType.toolExecution;

  /// Check if message is an autonomous action
  bool get isAutonomousAction => type == MessageType.autonomousAction;

  /// Check if message is an error
  bool get isErrorMessage => type == MessageType.error;

  /// Check if message is a typing indicator
  bool get isTypingIndicator => type == MessageType.typing;

  /// Check if message has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if message is a reply
  bool get isReply => replyToId != null;

  /// Check if message has been read
  bool get isRead => status == MessageStatus.read;

  /// Check if message is sending
  bool get isSending => status == MessageStatus.sending;

  /// Check if message failed to send
  bool get hasFailed => status == MessageStatus.failed;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'content': content,
      'status': status.name,
      'userId': userId,
      'metadata': metadata,
      'recognizedIntent': recognizedIntent?.toJson(),
      'autonomousAction': autonomousAction?.toJson(),
      'toolResult': toolResult?.toJson(),
      'attachments': attachments,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'replyToId': replyToId,
      'readBy': readBy,
    };
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.user,
      ),
      content: json['content'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      userId: json['userId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      recognizedIntent: json['recognizedIntent'] != null
          ? UserIntent.fromJson(json['recognizedIntent'])
          : null,
      autonomousAction: json['autonomousAction'] != null
          ? AutonomousAction.fromJson(json['autonomousAction'])
          : null,
      toolResult: json['toolResult'] != null
          ? ToolResult.fromJson(json['toolResult'])
          : null,
      attachments: List<String>.from(json['attachments'] ?? []),
      isEdited: json['isEdited'] ?? false,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      replyToId: json['replyToId'],
      readBy: List<String>.from(json['readBy'] ?? []),
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $type, status: $status, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
