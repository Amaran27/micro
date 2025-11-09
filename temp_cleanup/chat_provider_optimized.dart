import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../domain/usecases/send_message_usecase.dart';
import 'chat_state.dart';
import '../../../../infrastructure/ai/provider_config_model.dart';
import '../../../../infrastructure/ai/adapters/provider_adapter.dart';
import '../../../../infrastructure/ai/providers/ai_provider_config.dart';
import '../../../../infrastructure/ai/mcp/mcp_service.dart';
import '../../../../infrastructure/ai/agent/agent_service.dart';

part 'chat_state.freezed.dart';

/// Optimized chat provider with performance improvements
/// Fixes: Excessive provider detection, message conversion overhead, debug logging

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isLoading,
    String? error,
  }) = _ChatState;
}

class OptimizedChatNotifier extends StateNotifier<ChatState> {
  final SendMessageUseCase _sendMessageUseCase;
  final AIProviderConfig _aiProviderConfig;
  
  // Cache active adapter to avoid expensive provider detection on every message
  ProviderAdapter? _cachedAdapter;
  String? _cachedProviderId;
  DateTime _adapterCacheTime = DateTime.now();
  static const Duration _adapterCacheExpiry = Duration(minutes: 5);
  
  // Lazy initialization of agent services (only when needed)
  MCPService? _mcpService;
  AgentService? _agentService;

  // Message history conversion cache
  final Map<String, List<ChatMessage>> _conversionCache = {};
  static const int _maxCacheSize = 50;

  String? _pendingTypingId;

  OptimizedChatNotifier(
    this._sendMessageUseCase,
    this._aiProviderConfig,
  ) : super(const ChatState());

  /// Get or create cached adapter with optimized provider detection
  Future<ProviderAdapter?> _getOptimizedAdapter() async {
    final now = DateTime.now();
    
    // Return cached adapter if still valid
    if (_cachedAdapter != null && 
        _cachedProviderId != null && 
        now.difference(_adapterCacheTime) < _adapterCacheExpiry) {
      if (kDebugMode) print('DEBUG: Using cached adapter: $_cachedProviderId');
      return _cachedAdapter;
    }

    // Optimized provider detection - direct lookup instead of nested loops
    try {
      final activeModels = _aiProviderConfig.getAllActiveModels();
      
      // Priority order: ZhipuAI -> Google -> First available
      final priorityProviders = ['zhipu-ai', 'google'];
      
      for (final providerId in priorityProviders) {
        final modelId = activeModels[providerId];
        if (modelId != null) {
          final adapter = _aiProviderConfig.getProvider(providerId);
          if (adapter != null && adapter.isInitialized) {
            _cachedAdapter = adapter;
            _cachedProviderId = providerId;
            _adapterCacheTime = now;
            if (kDebugMode) print('DEBUG: Cached adapter: $providerId');
            return adapter;
          }
        }
      }
      
      // Fallback to any available provider
      for (final entry in activeModels.entries) {
        final adapter = _aiProviderConfig.getProvider(entry.key);
        if (adapter != null && adapter.isInitialized) {
          _cachedAdapter = adapter;
          _cachedProviderId = entry.key;
          _adapterCacheTime = now;
          if (kDebugMode) print('DEBUG: Cached fallback adapter: ${entry.key}');
          return adapter;
        }
      }
    } catch (e) {
      if (kDebugMode) print('DEBUG: Error in optimized adapter detection: $e');
    }
    
    return null;
  }

  /// Optimized message conversion with caching
  List<ChatMessage> _convertHistoryWithCache(List<ChatMessage> history) {
    // Create cache key from message IDs and content
    final cacheKey = history.map((m) => '${m.id}:${m.content.hashCode}').join('|');
    
    if (_conversionCache.containsKey(cacheKey)) {
      return _conversionCache[cacheKey]!;
    }
    
    // Convert messages (optimized version)
    final converted = history.where((m) => m.id != _pendingTypingId).toList();
    
    // Cache management - prevent memory leaks
    if (_conversionCache.length >= _maxCacheSize) {
      final firstKey = _conversionCache.keys.first;
      _conversionCache.remove(firstKey);
    }
    
    _conversionCache[cacheKey] = converted;
    return converted;
  }

  /// Initialize agent services only when needed
  void _ensureAgentServicesInitialized() {
    if (_mcpService == null || _agentService == null) {
      _mcpService = MCPService();
      _agentService = AgentService(mcpService: _mcpService!);
      if (kDebugMode) print('DEBUG: Agent services initialized on-demand');
    }
  }

  /// Optimized sendMessage with reduced overhead
  Future<void> sendMessage(String text,
      {bool agentMode = false, bool swarmMode = false}) async {
    if (text.trim().isEmpty) return;

    final startTime = DateTime.now();

    // Create user message
    final userMessage = ChatMessage.user(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      userId: 'user',
    );

    // Update state immediately for better UX
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // Add typing placeholder only if not using agent/swarm mode (they handle their own UI)
    if (!agentMode && !swarmMode) {
      final placeholderId = 'assistant_typing_${DateTime.now().millisecondsSinceEpoch}';
      final typingPlaceholder = ChatMessage.typing(
        id: placeholderId,
        userId: 'ai',
      );
      _pendingTypingId = placeholderId;
      state = state.copyWith(
        messages: [...state.messages, typingPlaceholder],
      );
    }

    try {
      // Agent/Swarm modes - initialize only when needed
      if (swarmMode) {
        _ensureAgentServicesInitialized();
        await _handleSwarmMessage(text, startTime);
        return;
      }
      
      if (agentMode) {
        _ensureAgentServicesInitialized();
        await _handleAgentMessage(text, startTime);
        return;
      }

      // Normal mode - optimized path
      await _handleNormalMessage(text, startTime);
      
    } catch (e) {
      _handleError(e, startTime);
    }
  }

  /// Optimized normal message handling
  Future<void> _handleNormalMessage(String text, DateTime startTime) async {
    final adapter = await _getOptimizedAdapter();
    
    if (adapter == null) {
      throw Exception('No AI provider available');
    }

    if (kDebugMode) {
      print('DEBUG: Using optimized adapter: ${adapter.providerId}');
    }

    final optimizedHistory = _convertHistoryWithCache(state.messages);

    if (adapter.supportsStreaming) {
      // Streaming implementation - optimized
      await for (final token in adapter.sendMessageStream(
        text: text,
        history: optimizedHistory,
      )) {
        // Update UI with streaming content
        _updateStreamingMessage(token);
      }
      _logLatency(startTime, mode: 'optimized-streaming');
    } else {
      // Non-streaming implementation
      final response = await adapter.sendMessage(
        text: text,
        history: optimizedHistory,
      );
      
      _finalizeMessage(response.content);
      _logLatency(startTime, mode: 'optimized-normal');
    }
  }

  /// Update streaming message efficiently
  void _updateStreamingMessage(String token) {
    final currentMessages = List<ChatMessage>.from(state.messages);
    
    // Find existing streaming message or create new content accumulator
    String currentContent = '';
    String messageId = '';
    
    try {
      final existingMessage = currentMessages.lastWhere(
        (m) => m.isFromAssistant && !m.isTypingIndicator,
      );
      currentContent = existingMessage.content;
      messageId = existingMessage.id;
    } catch (e) {
      // No existing message, create new ID
      messageId = 'assistant_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Create new message with updated content
    final updatedMessage = ChatMessage.assistant(
      id: messageId,
      content: currentContent + token,
      userId: 'ai',
    );
    
    // Replace or add the message
    final updatedMessages = currentMessages.where((m) => m.id != messageId).toList();
    updatedMessages.add(updatedMessage);
    
    state = state.copyWith(messages: updatedMessages);
  }

  /// Finalize message and remove typing placeholder
  void _finalizeMessage(String content) {
    final updatedMessages = state.messages
        .where((m) => m.id != _pendingTypingId)
        .toList()
      ..add(ChatMessage.assistant(
        id: 'assistant_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        userId: 'ai',
      ));
    
    _pendingTypingId = null;
    state = state.copyWith(
      messages: updatedMessages,
      isLoading: false,
    );
  }

  /// Handle swarm mode (placeholder - to be implemented)
  Future<void> _handleSwarmMessage(String text, DateTime startTime) async {
    // TODO: Implement optimized swarm handling
    _finalizeMessage('Swarm mode response for: $text');
    _logLatency(startTime, mode: 'swarm');
  }

  /// Handle agent mode (placeholder - to be implemented)
  Future<void> _handleAgentMessage(String text, DateTime startTime) async {
    // TODO: Implement optimized agent handling
    _finalizeMessage('Agent mode response for: $text');
    _logLatency(startTime, mode: 'agent');
  }

  /// Error handling
  void _handleError(Object error, DateTime startTime) {
    if (kDebugMode) print('DEBUG: Error in sendMessage: $error');
    
    _finalizeMessage('Sorry, I encountered an error. Please try again.');
    _logLatency(startTime, mode: 'error');
  }

  /// Optimized latency logging
  void _logLatency(DateTime start, {required String mode}) {
    if (kDebugMode) {
      final elapsed = DateTime.now().difference(start);
      print('LATENCY [$mode]: ${elapsed.inMilliseconds} ms total');
    }
  }

  /// Clear cache and reset state
  void clearCache() {
    _cachedAdapter = null;
    _cachedProviderId = null;
    _conversionCache.clear();
    if (kDebugMode) print('DEBUG: Chat provider cache cleared');
  }

  /// Retry last message
  Future<void> retryLastMessage() async {
    final userMessages = state.messages.where((m) => m.isFromUser).toList();
    if (userMessages.isNotEmpty) {
      final lastUserMessage = userMessages.last;
      // Remove the last failed response if any
      final updatedMessages = state.messages
          .where((m) => m.isFromUser || m.id == lastUserMessage.id)
          .toList();
      state = state.copyWith(messages: updatedMessages);
      
      await sendMessage(lastUserMessage.content);
    }
  }
}

/// Provider for optimized chat functionality
final optimizedChatProvider = StateNotifierProvider<OptimizedChatNotifier, ChatState>((ref) {
  final sendMessageUseCase = ref.watch(sendMessageUseCaseProvider);
  final aiProviderConfig = ref.watch(aiProviderConfigProvider);
  
  return OptimizedChatNotifier(
    sendMessageUseCase,
    aiProviderConfig,
  );
});