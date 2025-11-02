import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Represents different WebSocket connection states
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Represents errors that can occur during WebSocket communication
class WebSocketError implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  WebSocketError({required this.message, this.originalError, this.stackTrace});

  @override
  String toString() => 'WebSocketError: $message';
}

/// Callback types for WebSocket events
typedef OnMessageCallback = void Function(dynamic message);
typedef OnErrorCallback = void Function(WebSocketError error);
typedef OnStateChangeCallback = void Function(WebSocketConnectionState state);

/// Manages WebSocket connection lifecycle and message streaming
class WebSocketClient {
  late WebSocketChannel _channel;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;

  final String _url;
  final Duration _reconnectDelay;
  final int _maxReconnectAttempts;

  int _reconnectAttempts = 0;
  bool _manualClose = false;

  // Event callbacks
  OnMessageCallback? _onMessage;
  OnErrorCallback? _onError;
  OnStateChangeCallback? _onStateChange;

  WebSocketClient({
    required String url,
    Duration reconnectDelay = const Duration(seconds: 3),
    int maxReconnectAttempts = 5,
  }) : _url = url,
       _reconnectDelay = reconnectDelay,
       _maxReconnectAttempts = maxReconnectAttempts;

  /// Current connection state
  WebSocketConnectionState get state => _state;

  /// Whether currently connected
  bool get isConnected => _state == WebSocketConnectionState.connected;

  /// Set message callback
  void onMessage(OnMessageCallback callback) {
    _onMessage = callback;
  }

  /// Set error callback
  void onError(OnErrorCallback callback) {
    _onError = callback;
  }

  /// Set state change callback
  void onStateChange(OnStateChangeCallback callback) {
    _onStateChange = callback;
  }

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_state == WebSocketConnectionState.connecting ||
        _state == WebSocketConnectionState.connected) {
      return;
    }

    _manualClose = false;
    _changeState(WebSocketConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      // Wait for connection to establish
      await _channel.ready;

      _reconnectAttempts = 0;
      _changeState(WebSocketConnectionState.connected);

      // Start listening for messages
      _listenForMessages();
    } catch (e, st) {
      _handleConnectionError(e, st);
    }
  }

  /// Send message through WebSocket
  void send(dynamic message) {
    if (!isConnected) {
      final error = WebSocketError(
        message: 'Cannot send message: not connected',
      );
      _onError?.call(error);
      throw error;
    }

    try {
      _channel.sink.add(message);
    } catch (e, st) {
      final error = WebSocketError(
        message: 'Failed to send message',
        originalError: e,
        stackTrace: st,
      );
      _onError?.call(error);
      throw error;
    }
  }

  /// Listen for incoming messages
  void _listenForMessages() {
    try {
      _channel.stream.listen(
        (message) {
          _onMessage?.call(message);
        },
        onError: (error, stackTrace) {
          final wsError = WebSocketError(
            message: 'WebSocket stream error',
            originalError: error,
            stackTrace: stackTrace,
          );
          _onError?.call(wsError);

          if (!_manualClose) {
            _attemptReconnect();
          }
        },
        onDone: () {
          if (!_manualClose) {
            _changeState(WebSocketConnectionState.disconnected);
            _attemptReconnect();
          } else {
            _changeState(WebSocketConnectionState.disconnected);
          }
        },
      );
    } catch (e, st) {
      _handleConnectionError(e, st);
    }
  }

  /// Attempt to reconnect after disconnection
  void _attemptReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _changeState(WebSocketConnectionState.reconnecting);

      Future.delayed(_reconnectDelay, () async {
        try {
          await connect();
        } catch (e) {
          // Recursively attempt reconnection
          if (!_manualClose) {
            _attemptReconnect();
          }
        }
      });
    } else {
      final error = WebSocketError(
        message: 'Max reconnection attempts reached',
      );
      _changeState(WebSocketConnectionState.error);
      _onError?.call(error);
    }
  }

  /// Handle connection errors
  void _handleConnectionError(dynamic error, StackTrace stackTrace) {
    final wsError = WebSocketError(
      message: 'WebSocket connection error: $error',
      originalError: error,
      stackTrace: stackTrace,
    );

    _changeState(WebSocketConnectionState.error);
    _onError?.call(wsError);

    if (!_manualClose) {
      _attemptReconnect();
    }
  }

  /// Change connection state and notify listeners
  void _changeState(WebSocketConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _onStateChange?.call(_state);
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _manualClose = true;
    _reconnectAttempts = 0;

    try {
      await _channel.sink.close(status.goingAway);
      _changeState(WebSocketConnectionState.disconnected);
    } catch (e, st) {
      final error = WebSocketError(
        message: 'Error during disconnect',
        originalError: e,
        stackTrace: st,
      );
      _onError?.call(error);
      _changeState(WebSocketConnectionState.disconnected);
    }
  }

  /// Close connection permanently (no reconnect)
  Future<void> close() async {
    _manualClose = true;
    await disconnect();
  }
}
