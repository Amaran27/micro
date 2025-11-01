/// ActiveRequest manager - Riverpod StateNotifier for managing active streaming requests.
///
/// Mobile constraint: only one network stream active at a time to preserve battery/bandwidth.
/// This prevents overlapping requests and ensures clean cancellation.
///
/// Usage:
///   1. Provider creates a stream via getProvider().createMessage(...)
///   2. Call activeRequestNotifier.start(stream: ..., cancelToken: ..., onChunk: ...)
///   3. Listen to chunks in UI via ref.watch()
///   4. When new message arrives, start() automatically cancels old request
///   5. On error/timeout, call cancel() to clean up resources
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/domain/models/api_stream.dart';

/// Represents an active streaming request with cancellation capability.
class ActiveRequest {
  /// CancelToken passed to Dio - call cancel() to stop the HTTP request
  final CancelToken cancelToken;

  /// Stream subscription - call cancel() to stop listening
  final StreamSubscription<ApiStreamChunk> subscription;

  ActiveRequest({
    required this.cancelToken,
    required this.subscription,
  });
}

/// StateNotifier that manages one active request at a time.
/// Ensures cancellation and cleanup when switching to a new request.
class ActiveRequestNotifier extends StateNotifier<ActiveRequest?> {
  ActiveRequestNotifier() : super(null);

  /// Start a new request stream.
  ///
  /// Automatically cancels any existing request (if one is active).
  /// Listens to the stream and calls callbacks for chunks, errors, completion.
  ///
  /// Args:
  ///   - stream: Stream<ApiStreamChunk> from provider.createMessage()
  ///   - cancelToken: Dio CancelToken for HTTP-level cancellation
  ///   - onChunk: callback when chunk arrives
  ///   - onError: callback on error (including stream errors)
  ///   - onDone: callback when stream completes normally
  void start({
    required Stream<ApiStreamChunk> stream,
    required CancelToken cancelToken,
    required void Function(ApiStreamChunk chunk) onChunk,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function() onDone,
  }) {
    // Cancel and clean up any existing request
    _cancelExisting();

    // Subscribe to the new stream
    final subscription = stream.listen(
      onChunk,
      onError: (Object error, StackTrace stackTrace) {
        // Let consumer handle error, but mark subscription as done
        onError(error, stackTrace);
      },
      onDone: onDone,
      cancelOnError: true,
    );

    // Store the new active request
    state = ActiveRequest(cancelToken: cancelToken, subscription: subscription);
  }

  /// Cancel the active request and clean up resources.
  /// Idempotent: safe to call multiple times or when no request is active.
  Future<void> cancel([String reason = 'user_cancel']) async {
    if (state == null) return;

    await _cancelExisting();
    state = null;
  }

  /// Internal: cancel existing request with error handling.
  Future<void> _cancelExisting() async {
    if (state == null) return;

    // Cancel the Dio request (stops HTTP stream)
    try {
      state!.cancelToken.cancel('new_request');
    } catch (_) {
      // already cancelled or disposed
    }

    // Cancel the subscription (stops listening to chunks)
    try {
      await state!.subscription.cancel();
    } catch (_) {
      // already cancelled
    }

    state = null;
  }

  /// Graceful shutdown: cancel everything.
  /// Call this in dispose() or when the app is shutting down.
  @override
  void dispose() {
    _cancelExisting();
    super.dispose();
  }
}

/// Riverpod StateNotifier provider for activeRequest management.
/// Scope: global (one active request for entire app) or scoped to conversation.
final activeRequestProvider =
    StateNotifierProvider<ActiveRequestNotifier, ActiveRequest?>(
  (ref) => ActiveRequestNotifier(),
);
