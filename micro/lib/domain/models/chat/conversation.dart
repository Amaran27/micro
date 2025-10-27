import 'chat_message.dart';

/// Conversation status
enum ConversationStatus {
  /// Active conversation
  active,

  /// Paused conversation
  paused,

  /// Archived conversation
  archived,

  /// Deleted conversation
  deleted,
}

/// Conversation model for managing chat sessions
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final List<ChatMessage> messages;
  final ConversationStatus status;
  final String? userId;
  final Map<String, dynamic> metadata;
  final int unreadCount;
  final List<String> participants;
  final bool isPinned;
  final String? lastMessagePreview;
  final int messageCount;

  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.messages = const [],
    this.status = ConversationStatus.active,
    this.userId,
    this.metadata = const {},
    this.unreadCount = 0,
    this.participants = const [],
    this.isPinned = false,
    this.lastMessagePreview,
    this.messageCount = 0,
  });

  /// Create a new conversation
  factory Conversation.create({
    required String id,
    required String title,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      lastMessageAt: now,
      userId: userId,
      metadata: metadata ?? {},
    );
  }

  /// Create a conversation with initial message
  factory Conversation.withInitialMessage({
    required String id,
    required String title,
    required ChatMessage initialMessage,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      lastMessageAt: now,
      messages: [initialMessage],
      userId: userId,
      metadata: metadata ?? {},
      messageCount: 1,
      lastMessagePreview: initialMessage.content.length > 50
          ? '${initialMessage.content.substring(0, 50)}...'
          : initialMessage.content,
    );
  }

  /// Add a message to the conversation
  Conversation addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages);
    updatedMessages.add(message);

    return Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: message.timestamp,
      messages: updatedMessages,
      status: status,
      userId: userId,
      metadata: metadata,
      unreadCount: message.isFromUser ? 0 : unreadCount + 1,
      participants: participants,
      isPinned: isPinned,
      lastMessagePreview: message.content.length > 50
          ? '${message.content.substring(0, 50)}...'
          : message.content,
      messageCount: messageCount + 1,
    );
  }

  /// Update conversation title
  Conversation updateTitle(String newTitle) {
    return Conversation(
      id: id,
      title: newTitle,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: lastMessageAt,
      messages: messages,
      status: status,
      userId: userId,
      metadata: metadata,
      unreadCount: unreadCount,
      participants: participants,
      isPinned: isPinned,
      lastMessagePreview: lastMessagePreview,
      messageCount: messageCount,
    );
  }

  /// Mark conversation as read
  Conversation markAsRead() {
    return Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: lastMessageAt,
      messages: messages,
      status: status,
      userId: userId,
      metadata: metadata,
      unreadCount: 0,
      participants: participants,
      isPinned: isPinned,
      lastMessagePreview: lastMessagePreview,
      messageCount: messageCount,
    );
  }

  /// Pin/unpin conversation
  Conversation togglePin() {
    return Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: lastMessageAt,
      messages: messages,
      status: status,
      userId: userId,
      metadata: metadata,
      unreadCount: unreadCount,
      participants: participants,
      isPinned: !isPinned,
      lastMessagePreview: lastMessagePreview,
      messageCount: messageCount,
    );
  }

  /// Archive conversation
  Conversation archive() {
    return Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: lastMessageAt,
      messages: messages,
      status: ConversationStatus.archived,
      userId: userId,
      metadata: metadata,
      unreadCount: unreadCount,
      participants: participants,
      isPinned: isPinned,
      lastMessagePreview: lastMessagePreview,
      messageCount: messageCount,
    );
  }

  /// Delete conversation
  Conversation delete() {
    return Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastMessageAt: lastMessageAt,
      messages: messages,
      status: ConversationStatus.deleted,
      userId: userId,
      metadata: metadata,
      unreadCount: unreadCount,
      participants: participants,
      isPinned: isPinned,
      lastMessagePreview: lastMessagePreview,
      messageCount: messageCount,
    );
  }

  /// Get last message
  ChatMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  /// Get user messages
  List<ChatMessage> get userMessages {
    return messages.where((message) => message.isFromUser).toList();
  }

  /// Get assistant messages
  List<ChatMessage> get assistantMessages {
    return messages.where((message) => message.isFromAssistant).toList();
  }

  /// Get system messages
  List<ChatMessage> get systemMessages {
    return messages.where((message) => message.isSystemMessage).toList();
  }

  /// Get tool execution messages
  List<ChatMessage> get toolExecutionMessages {
    return messages.where((message) => message.isToolExecution).toList();
  }

  /// Get autonomous action messages
  List<ChatMessage> get autonomousActionMessages {
    return messages.where((message) => message.isAutonomousAction).toList();
  }

  /// Get error messages
  List<ChatMessage> get errorMessages {
    return messages.where((message) => message.isErrorMessage).toList();
  }

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Check if conversation is active
  bool get isActive => status == ConversationStatus.active;

  /// Check if conversation is archived
  bool get isArchived => status == ConversationStatus.archived;

  /// Check if conversation is deleted
  bool get isDeleted => status == ConversationStatus.deleted;

  /// Check if conversation is empty
  bool get isEmpty => messages.isEmpty;

  /// Check if conversation has messages
  bool get hasMessages => messages.isNotEmpty;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'status': status.name,
      'userId': userId,
      'metadata': metadata,
      'unreadCount': unreadCount,
      'participants': participants,
      'isPinned': isPinned,
      'lastMessagePreview': lastMessagePreview,
      'messageCount': messageCount,
    };
  }

  /// Create from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((messageJson) => ChatMessage.fromJson(messageJson))
              .toList() ??
          [],
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConversationStatus.active,
      ),
      userId: json['userId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      unreadCount: json['unreadCount'] ?? 0,
      participants: List<String>.from(json['participants'] ?? []),
      isPinned: json['isPinned'] ?? false,
      lastMessagePreview: json['lastMessagePreview'],
      messageCount: json['messageCount'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, title: $title, messageCount: $messageCount, status: $status, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
