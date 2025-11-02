import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/chat_model.dart';
import '../communication/message_serializer.dart';
import '../communication/websocket_provider.dart';

/// Represents an event in the agent stream
class AgentStreamEvent {
  final String eventId;
  final String taskId;
  final AgentStreamEventType type;
  final dynamic data;
  final DateTime timestamp;
  final String? error;

  AgentStreamEvent({
    required this.eventId,
    required this.taskId,
    required this.type,
    required this.data,
    required this.timestamp,
    this.error,
  });

  factory AgentStreamEvent.fromMessage(SerializableMessage message) {
    final type = message.type;
    AgentStreamEventType eventType;

    switch (type) {
      case MessageType.plan:
        eventType = AgentStreamEventType.planGenerated;
      case MessageType.stepExecution:
        eventType = AgentStreamEventType.stepStarted;
      case MessageType.verification:
        eventType = AgentStreamEventType.verificationComplete;
      case MessageType.streamStart:
        eventType = AgentStreamEventType.streamStart;
      case MessageType.streamEnd:
        eventType = AgentStreamEventType.streamEnd;
      case MessageType.error:
        eventType = AgentStreamEventType.error;
      default:
        eventType = AgentStreamEventType.unknown;
    }

    return AgentStreamEvent(
      eventId: message.id,
      taskId: message.payload['taskId'] ?? 'unknown',
      type: eventType,
      data: message.payload,
      timestamp: message.timestamp,
      error: message.payload['message'] as String?,
    );
  }

  @override
  String toString() =>
      'AgentStreamEvent(id: $eventId, type: $type, timestamp: $timestamp)';
}

/// Types of events that can occur in agent stream
enum AgentStreamEventType {
  planGenerated,
  stepStarted,
  stepCompleted,
  verificationComplete,
  streamStart,
  streamEnd,
  error,
  unknown,
}

/// Manages streaming agent responses
class StreamingAgentNotifier extends StateNotifier<List<AgentStreamEvent>> {
  final WebSocketNotifier webSocketNotifier;
  final Ref ref;
  late StreamSubscription<dynamic> _messageSubscription;
  late StreamSubscription<WebSocketConnectionState> _connectionSubscription;

  String _currentTaskId = '';
  final _eventController = StreamController<AgentStreamEvent>.broadcast();

  StreamingAgentNotifier({required this.webSocketNotifier, required this.ref})
    : super([]) {
    _initializeListeners();
  }

  /// Stream of agent events
  Stream<AgentStreamEvent> get events => _eventController.stream;

  /// Initialize listeners for WebSocket messages
  void _initializeListeners() {
    // Listen for WebSocket messages
    webSocketNotifier.addListener((newState) {
      if (newState.lastMessage != null) {
        _handleIncomingMessage(newState.lastMessage);
      }
    });
  }

  /// Handle incoming message from WebSocket
  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final message = MessageSerializer.decodeFromWebSocket(rawMessage);
      final event = AgentStreamEvent.fromMessage(message);

      // Update state
      state = [...state, event];

      // Emit to stream
      _eventController.add(event);
    } catch (e) {
      // Handle deserialization error
      final errorEvent = AgentStreamEvent(
        eventId: const Uuid().v4(),
        taskId: _currentTaskId,
        type: AgentStreamEventType.error,
        data: {'error': 'Failed to deserialize message: $e'},
        timestamp: DateTime.now(),
        error: 'Message deserialization failed',
      );
      state = [...state, errorEvent];
      _eventController.addError(e);
    }
  }

  /// Start streaming agent response for a task
  Future<void> startStreamingTask(String taskId) async {
    _currentTaskId = taskId;

    // Send stream start message
    final startMessage = MessageSerializer.createStreamStartMessage(id: taskId);
    webSocketNotifier.send(MessageSerializer.encodeForWebSocket(startMessage));

    // Clear previous events for this task
    state = state.where((e) => e.taskId != taskId).toList();
  }

  /// Stop streaming agent response
  Future<void> stopStreamingTask(String taskId) async {
    // Send stream end message
    final endMessage = MessageSerializer.createStreamEndMessage(id: taskId);
    webSocketNotifier.send(MessageSerializer.encodeForWebSocket(endMessage));
  }

  /// Send a plan request to the agent
  Future<void> requestPlan(String taskDescription) async {
    final taskId = const Uuid().v4();
    _currentTaskId = taskId;

    final message = SerializableMessage(
      id: taskId,
      type: MessageType.plan,
      timestamp: DateTime.now(),
      payload: {'taskId': taskId, 'description': taskDescription},
    );

    webSocketNotifier.send(MessageSerializer.encodeForWebSocket(message));
  }

  /// Send a command to execute a specific step
  Future<void> executeStep(String taskId, int stepNumber) async {
    final message = SerializableMessage(
      id: const Uuid().v4(),
      type: MessageType.stepExecution,
      timestamp: DateTime.now(),
      payload: {'taskId': taskId, 'stepNumber': stepNumber},
    );

    webSocketNotifier.send(MessageSerializer.encodeForWebSocket(message));
  }

  /// Request verification of results
  Future<void> requestVerification(String taskId, dynamic results) async {
    final message = SerializableMessage(
      id: const Uuid().v4(),
      type: MessageType.verification,
      timestamp: DateTime.now(),
      payload: {'taskId': taskId, 'results': results},
    );

    webSocketNotifier.send(MessageSerializer.encodeForWebSocket(message));
  }

  /// Get events for a specific task
  List<AgentStreamEvent> getTaskEvents(String taskId) {
    return state.where((event) => event.taskId == taskId).toList();
  }

  /// Clear all events
  void clearEvents() {
    state = [];
  }

  /// Clear events for specific task
  void clearTaskEvents(String taskId) {
    state = state.where((e) => e.taskId != taskId).toList();
  }

  @override
  void dispose() {
    _eventController.close();
    _messageSubscription.cancel();
    _connectionSubscription.cancel();
    super.dispose();
  }
}

/// Riverpod provider for streaming agent
final streamingAgentProvider =
    StateNotifierProvider<StreamingAgentNotifier, List<AgentStreamEvent>>((
      ref,
    ) {
      final webSocketNotifier = ref.watch(webSocketProvider.notifier);
      return StreamingAgentNotifier(
        webSocketNotifier: webSocketNotifier,
        ref: ref,
      );
    });

/// Helper provider to get stream of events
final agentEventsStreamProvider = StreamProvider<AgentStreamEvent>((
  ref,
) async* {
  final streamingAgent = ref.watch(streamingAgentProvider.notifier);
  yield* streamingAgent.events;
});

/// Helper provider to get events for current task
final currentTaskEventsProvider =
    Provider.family<List<AgentStreamEvent>, String>((ref, taskId) {
      final streamingAgent = ref.watch(streamingAgentProvider);
      return streamingAgent.where((event) => event.taskId == taskId).toList();
    });

/// Helper provider to check if streaming
final isStreamingProvider = Provider<bool>((ref) {
  final events = ref.watch(streamingAgentProvider);
  return events.isNotEmpty &&
      events.any((e) => e.type == AgentStreamEventType.streamStart);
});
