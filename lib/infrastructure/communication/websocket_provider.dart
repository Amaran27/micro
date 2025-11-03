import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'websocket_client.dart';

/// WebSocket provider configuration
class WebSocketConfig {
  final String url;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;

  WebSocketConfig({
    required this.url,
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 5,
  });
}

/// State holder for WebSocket connection
class WebSocketState {
  final WebSocketConnectionState connectionState;
  final dynamic lastMessage;
  final WebSocketError? lastError;
  final DateTime? lastConnected;

  WebSocketState({
    this.connectionState = WebSocketConnectionState.disconnected,
    this.lastMessage,
    this.lastError,
    this.lastConnected,
  });

  WebSocketState copyWith({
    WebSocketConnectionState? connectionState,
    dynamic lastMessage,
    WebSocketError? lastError,
    DateTime? lastConnected,
  }) {
    return WebSocketState(
      connectionState: connectionState ?? this.connectionState,
      lastMessage: lastMessage ?? this.lastMessage,
      lastError: lastError ?? this.lastError,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  bool get isConnected => connectionState == WebSocketConnectionState.connected;
}

/// Notifier for managing WebSocket state
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  late WebSocketClient _client;
  final WebSocketConfig config;

  WebSocketNotifier(this.config) : super(WebSocketState());

  /// Initialize WebSocket client
  void _initializeClient() {
    _client = WebSocketClient(
      url: config.url,
      reconnectDelay: config.reconnectDelay,
      maxReconnectAttempts: config.maxReconnectAttempts,
    );

    // Set up callbacks
    _client.onMessage((message) {
      state = state.copyWith(
        lastMessage: message,
        connectionState: WebSocketConnectionState.connected,
      );
    });

    _client.onError((error) {
      state = state.copyWith(
        lastError: error,
        connectionState: WebSocketConnectionState.error,
      );
    });

    _client.onStateChange((connectionState) {
      final now = connectionState == WebSocketConnectionState.connected
          ? DateTime.now()
          : state.lastConnected;

      state = state.copyWith(
        connectionState: connectionState,
        lastConnected: now,
      );
    });
  }

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (state.isConnected) return;

    _initializeClient();
    try {
      await _client.connect();
    } catch (e) {
      final error = e is WebSocketError
          ? e
          : WebSocketError(message: 'Failed to connect: $e', originalError: e);
      state = state.copyWith(lastError: error);
      rethrow;
    }
  }

  /// Send a message through WebSocket
  void send(dynamic message) {
    if (!state.isConnected) {
      final error = WebSocketError(message: 'WebSocket not connected');
      state = state.copyWith(lastError: error);
      throw error;
    }
    _client.send(message);
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    await _client.disconnect();
  }

  /// Close the WebSocket connection permanently
  Future<void> close() async {
    await _client.close();
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}

/// Riverpod provider for WebSocket configuration
final webSocketConfigProvider = Provider<WebSocketConfig>((ref) {
  // Default configuration - can be overridden
  return WebSocketConfig(url: 'ws://localhost:8080/agent');
});

/// Riverpod StateNotifier provider for WebSocket
final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
      final config = ref.watch(webSocketConfigProvider);
      return WebSocketNotifier(config);
    });

/// Helper provider to get connection state
final webSocketConnectionStateProvider = Provider<WebSocketConnectionState>((
  ref,
) {
  return ref.watch(webSocketProvider).connectionState;
});

/// Helper provider to check if connected
final webSocketIsConnectedProvider = Provider<bool>((ref) {
  return ref.watch(webSocketProvider).isConnected;
});

/// Helper provider to get last error
final webSocketLastErrorProvider = Provider<WebSocketError?>((ref) {
  return ref.watch(webSocketProvider).lastError;
});

/// Helper provider to get last message
final webSocketLastMessageProvider = Provider<dynamic>((ref) {
  return ref.watch(webSocketProvider).lastMessage;
});
