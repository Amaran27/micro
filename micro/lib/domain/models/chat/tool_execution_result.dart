import '../../../infrastructure/mcp/core/models/tool_result.dart';

/// Tool execution result status for chat
enum ChatToolExecutionStatus {
  /// Tool execution is queued
  queued,

  /// Tool execution is in progress
  executing,

  /// Tool execution completed successfully
  completed,

  /// Tool execution failed
  failed,

  /// Tool execution was cancelled
  cancelled,
}

/// Enhanced tool execution result for chat interface
class ChatToolExecutionResult {
  final String id;
  final String toolId;
  final String toolName;
  final String? serverName;
  final ChatToolExecutionStatus status;
  final DateTime timestamp;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? executionDuration;
  final Map<String, dynamic> parameters;
  final ToolResult? result;
  final String? errorMessage;
  final List<String> warnings;
  final Map<String, dynamic> metadata;
  final String? messageId;
  final bool isUserInitiated;
  final bool requiresUserApproval;
  final bool userApproved;
  final String? userId;

  const ChatToolExecutionResult({
    required this.id,
    required this.toolId,
    required this.toolName,
    this.serverName,
    required this.status,
    required this.timestamp,
    this.startedAt,
    this.completedAt,
    this.executionDuration,
    this.parameters = const {},
    this.result,
    this.errorMessage,
    this.warnings = const [],
    this.metadata = const {},
    this.messageId,
    this.isUserInitiated = true,
    this.requiresUserApproval = false,
    this.userApproved = false,
    this.userId,
  });

  /// Create a queued tool execution
  factory ChatToolExecutionResult.queued({
    required String id,
    required String toolId,
    required String toolName,
    required Map<String, dynamic> parameters,
    String? serverName,
    String? messageId,
    String? userId,
    bool requiresUserApproval = false,
  }) {
    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.queued,
      timestamp: DateTime.now(),
      parameters: parameters,
      messageId: messageId,
      userId: userId,
      requiresUserApproval: requiresUserApproval,
    );
  }

  /// Create an executing tool execution
  factory ChatToolExecutionResult.executing({
    required String id,
    required String toolId,
    required String toolName,
    required Map<String, dynamic> parameters,
    String? serverName,
    String? messageId,
    String? userId,
  }) {
    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.executing,
      timestamp: DateTime.now(),
      startedAt: DateTime.now(),
      parameters: parameters,
      messageId: messageId,
      userId: userId,
    );
  }

  /// Create a completed tool execution
  factory ChatToolExecutionResult.completed({
    required String id,
    required String toolId,
    required String toolName,
    required ToolResult result,
    required Map<String, dynamic> parameters,
    String? serverName,
    String? messageId,
    String? userId,
    List<String> warnings = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    final startedAt = metadata['startedAt'] != null
        ? DateTime.parse(metadata['startedAt'])
        : now;

    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.completed,
      timestamp: now,
      startedAt: startedAt,
      completedAt: now,
      executionDuration: now.difference(startedAt),
      parameters: parameters,
      result: result,
      warnings: warnings,
      metadata: {
        ...metadata,
        'completedAt': now.toIso8601String(),
      },
      messageId: messageId,
      userId: userId,
    );
  }

  /// Create a failed tool execution
  factory ChatToolExecutionResult.failed({
    required String id,
    required String toolId,
    required String toolName,
    required String errorMessage,
    required Map<String, dynamic> parameters,
    String? serverName,
    String? messageId,
    String? userId,
    List<String> warnings = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    final startedAt = metadata['startedAt'] != null
        ? DateTime.parse(metadata['startedAt'])
        : now;

    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.failed,
      timestamp: now,
      startedAt: startedAt,
      completedAt: now,
      executionDuration: now.difference(startedAt),
      parameters: parameters,
      errorMessage: errorMessage,
      warnings: warnings,
      metadata: {
        ...metadata,
        'failedAt': now.toIso8601String(),
        'errorMessage': errorMessage,
      },
      messageId: messageId,
      userId: userId,
    );
  }

  /// Create a cancelled tool execution
  factory ChatToolExecutionResult.cancelled({
    required String id,
    required String toolId,
    required String toolName,
    required Map<String, dynamic> parameters,
    String? serverName,
    String? messageId,
    String? userId,
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    final startedAt = metadata['startedAt'] != null
        ? DateTime.parse(metadata['startedAt'])
        : now;

    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.cancelled,
      timestamp: now,
      startedAt: startedAt,
      completedAt: now,
      executionDuration: now.difference(startedAt),
      parameters: parameters,
      metadata: {
        ...metadata,
        'cancelledAt': now.toIso8601String(),
      },
      messageId: messageId,
      userId: userId,
    );
  }

  /// Mark execution as started
  ChatToolExecutionResult markAsStarted() {
    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.executing,
      timestamp: timestamp,
      startedAt: DateTime.now(),
      completedAt: completedAt,
      executionDuration: executionDuration,
      parameters: parameters,
      result: result,
      errorMessage: errorMessage,
      warnings: warnings,
      metadata: metadata,
      messageId: messageId,
      isUserInitiated: isUserInitiated,
      requiresUserApproval: requiresUserApproval,
      userApproved: userApproved,
      userId: userId,
    );
  }

  /// Mark execution as completed with result
  ChatToolExecutionResult markAsCompleted(ToolResult toolResult,
      {List<String>? additionalWarnings}) {
    final now = DateTime.now();
    final startedAt = this.startedAt ?? now;

    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.completed,
      timestamp: now,
      startedAt: startedAt,
      completedAt: now,
      executionDuration: now.difference(startedAt),
      parameters: parameters,
      result: toolResult,
      warnings: [...warnings, ...additionalWarnings ?? []],
      metadata: {
        ...metadata,
        'completedAt': now.toIso8601String(),
      },
      messageId: messageId,
      isUserInitiated: isUserInitiated,
      requiresUserApproval: requiresUserApproval,
      userApproved: userApproved,
      userId: userId,
    );
  }

  /// Mark execution as failed
  ChatToolExecutionResult markAsFailed(String errorMessage,
      {List<String>? additionalWarnings}) {
    final now = DateTime.now();
    final startedAt = this.startedAt ?? now;

    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.failed,
      timestamp: now,
      startedAt: startedAt,
      completedAt: now,
      executionDuration: now.difference(startedAt),
      parameters: parameters,
      errorMessage: errorMessage,
      warnings: [...warnings, ...additionalWarnings ?? []],
      metadata: {
        ...metadata,
        'failedAt': now.toIso8601String(),
        'errorMessage': errorMessage,
      },
      messageId: messageId,
      isUserInitiated: isUserInitiated,
      requiresUserApproval: requiresUserApproval,
      userApproved: userApproved,
      userId: userId,
    );
  }

  /// Mark execution as cancelled
  ChatToolExecutionResult markAsCancelled() {
    final now = DateTime.now();
    final startedAt = this.startedAt ?? now;

    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: ChatToolExecutionStatus.cancelled,
      timestamp: now,
      startedAt: startedAt,
      completedAt: now,
      executionDuration: now.difference(startedAt),
      parameters: parameters,
      result: result,
      errorMessage: errorMessage,
      warnings: warnings,
      metadata: {
        ...metadata,
        'cancelledAt': now.toIso8601String(),
      },
      messageId: messageId,
      isUserInitiated: isUserInitiated,
      requiresUserApproval: requiresUserApproval,
      userApproved: userApproved,
      userId: userId,
    );
  }

  /// Approve execution for user
  ChatToolExecutionResult approve() {
    return ChatToolExecutionResult(
      id: id,
      toolId: toolId,
      toolName: toolName,
      serverName: serverName,
      status: status,
      timestamp: timestamp,
      startedAt: startedAt,
      completedAt: completedAt,
      executionDuration: executionDuration,
      parameters: parameters,
      result: result,
      errorMessage: errorMessage,
      warnings: warnings,
      metadata: metadata,
      messageId: messageId,
      isUserInitiated: isUserInitiated,
      requiresUserApproval: requiresUserApproval,
      userApproved: true,
      userId: userId,
    );
  }

  /// Check if execution is queued
  bool get isQueued => status == ChatToolExecutionStatus.queued;

  /// Check if execution is in progress
  bool get isExecuting => status == ChatToolExecutionStatus.executing;

  /// Check if execution is completed
  bool get isCompleted => status == ChatToolExecutionStatus.completed;

  /// Check if execution failed
  bool get isFailed => status == ChatToolExecutionStatus.failed;

  /// Check if execution was cancelled
  bool get isCancelled => status == ChatToolExecutionStatus.cancelled;

  /// Check if execution is active (queued or executing)
  bool get isActive => [
        ChatToolExecutionStatus.queued,
        ChatToolExecutionStatus.executing
      ].contains(status);

  /// Check if execution is finished (completed, failed, or cancelled)
  bool get isFinished => [
        ChatToolExecutionStatus.completed,
        ChatToolExecutionStatus.failed,
        ChatToolExecutionStatus.cancelled
      ].contains(status);

  /// Check if execution was successful
  bool get isSuccess => isCompleted && result?.isSuccess == true;

  /// Check if execution requires user approval
  bool get needsApproval => requiresUserApproval && !userApproved;

  /// Check if execution has warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Check if execution has result
  bool get hasResult => result != null;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolId': toolId,
      'toolName': toolName,
      'serverName': serverName,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'executionDuration': executionDuration?.inMilliseconds,
      'parameters': parameters,
      'result': result?.toJson(),
      'errorMessage': errorMessage,
      'warnings': warnings,
      'metadata': metadata,
      'messageId': messageId,
      'isUserInitiated': isUserInitiated,
      'requiresUserApproval': requiresUserApproval,
      'userApproved': userApproved,
      'userId': userId,
    };
  }

  /// Create from JSON
  factory ChatToolExecutionResult.fromJson(Map<String, dynamic> json) {
    return ChatToolExecutionResult(
      id: json['id'],
      toolId: json['toolId'],
      toolName: json['toolName'],
      serverName: json['serverName'],
      status: ChatToolExecutionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChatToolExecutionStatus.queued,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      startedAt:
          json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      executionDuration: json['executionDuration'] != null
          ? Duration(milliseconds: json['executionDuration'])
          : null,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      result:
          json['result'] != null ? ToolResult.fromJson(json['result']) : null,
      errorMessage: json['errorMessage'],
      warnings: List<String>.from(json['warnings'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      messageId: json['messageId'],
      isUserInitiated: json['isUserInitiated'] ?? true,
      requiresUserApproval: json['requiresUserApproval'] ?? false,
      userApproved: json['userApproved'] ?? false,
      userId: json['userId'],
    );
  }

  @override
  String toString() {
    return 'ChatToolExecutionResult(id: $id, toolId: $toolId, status: $status, isSuccess: $isSuccess)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatToolExecutionResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
