import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_core/chat_models.dart' as langchain;
import 'package:micro/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:micro/infrastructure/ai/ai_provider_config.dart';
import 'package:micro/infrastructure/ai/interfaces/provider_adapter.dart';
import 'package:micro/infrastructure/ai/interfaces/provider_config.dart' as pc;
import 'package:micro/features/chat/data/sources/llm_data_source.dart';
import 'package:micro/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:micro/features/chat/domain/utils/chat_message_converter.dart';
import 'package:micro/infrastructure/ai/model_selection_service.dart';
import 'package:micro/core/utils/logger.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;

import 'dart:convert';

class ChatState {
  final List<micro.ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<micro.ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final aiProviderConfigProvider = Provider((ref) => AIProviderConfig());

final llmDataSourceProvider = Provider(
  (ref) => LlmDataSource(ref.watch(aiProviderConfigProvider)),
);

final chatRepositoryProvider = Provider(
  (ref) => ChatRepositoryImpl(ref.watch(llmDataSourceProvider)),
);

final sendMessageUseCaseProvider = Provider(
  (ref) => SendMessageUseCase(ref.watch(chatRepositoryProvider)),
);

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref.watch(aiProviderConfigProvider), ref),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final AIProviderConfig _aiProviderConfig;
  final Ref _ref;
  
  // Performance optimization: Cache adapter by exact provider+model combination
  final Map<String, ProviderAdapter> _adapterCache = {};  // "providerId:modelId" -> adapter
  final Map<String, DateTime> _adapterCacheTime = {};     // "providerId:modelId" -> timestamp
  static const Duration _adapterCacheExpiry = Duration(minutes: 5);
  
  String? _pendingTypingId;

  ChatNotifier(this._aiProviderConfig, this._ref) : super(ChatState()) {
    _initializeAIProvider();
  }

  Future<void> _initializeAIProvider() async {
    // Only initialize once, check if already initialized
    if (!_aiProviderConfig.isInitialized) {
      await _aiProviderConfig.initialize();
    }
  }

  /// True reactive provider+model caching using AIProviderConfig
  Future<ProviderAdapter?> _getOptimizedAdapter() async {
    final now = DateTime.now();
    
    try {
      // Fast path: Use AIProviderConfig's active models (already loaded during initialization)
      final activeModels = _aiProviderConfig.getAllActiveModels();
      
      if (activeModels.isEmpty) {
        // Only fallback to ModelSelectionService if absolutely necessary
        final modelService = ModelSelectionService.instance;
        if (!modelService.isInitialized) {
          await modelService.initialize();
        }
        final fallbackModels = modelService.getAllActiveModels();
        if (fallbackModels.isEmpty) {
          if (kDebugMode) print('DEBUG: No active models found');
          return null;
        }
        return await _selectOptimalProvider(fallbackModels);
      }
      
      return await _selectOptimalProvider(activeModels);
    } catch (e) {
      AppLogger().error('Error getting optimized adapter', error: e);
      return null;
    }
  }

  /// Select the provider based on user's current selection
  Future<ProviderAdapter?> _selectOptimalProvider(Map<String, String> activeModels) async {
    // Get the user's current selected model from UI
    final currentSelectedModel = await _getCurrentUserSelectedModel();
    
    if (currentSelectedModel != null && activeModels.isNotEmpty) {
      // Find which provider matches the user's selected model
      for (final entry in activeModels.entries) {
        if (entry.value == currentSelectedModel) {
          final provider = entry.key;
          final model = entry.value;
          if (kDebugMode) print('DEBUG: Using user selected provider+model: $provider:$model');
          return await _getAdapterForProvider(provider, model);
        }
      }
      
      // If exact model match not found, use the provider that has the user's selected model
      final userProvider = _detectProviderFromModel(currentSelectedModel);
      if (activeModels.containsKey(userProvider)) {
        final model = activeModels[userProvider]!;
        if (kDebugMode) print('DEBUG: using user provider: $userProvider with model: $model');
        return await _getAdapterForProvider(userProvider, model);
      }
    }
    
    // No user selection found, return null (no fallback)
    if (kDebugMode) print('DEBUG: No user selection found, returning null');
    return null;
  }

  /// Get adapter for specific provider and model with caching
  Future<ProviderAdapter?> _getAdapterForProvider(String providerId, String modelId) async {
    final now = DateTime.now();
    final cacheKey = '$providerId:$modelId';
    
    if (kDebugMode) print('DEBUG: Using provider+model: $cacheKey');
    
    // Check cache first
    if (_adapterCache.containsKey(cacheKey)) {
      final cacheTime = _adapterCacheTime[cacheKey] ?? DateTime.now();
      if (now.difference(cacheTime) < _adapterCacheExpiry) {
        final cachedAdapter = _adapterCache[cacheKey];
        if (kDebugMode) print('DEBUG: Using cached adapter: $cacheKey');
        return cachedAdapter;
      } else {
        // Cache expired, remove it
        _adapterCache.remove(cacheKey);
        _adapterCacheTime.remove(cacheKey);
      }
    }
    
    // Get adapter for the provider (async with lazy initialization)
    var adapter = await _aiProviderConfig.getProvider(providerId);
    if (kDebugMode) print('DEBUG: _getOptimizedAdapter() - adapter from getProvider: ${adapter?.runtimeType}');
    
    if (adapter != null && adapter.currentModel != modelId) {
      if (kDebugMode) print('DEBUG: _getOptimizedAdapter() - switching model from ${adapter.currentModel} to $modelId');
      // Update adapter to use current model
      await adapter.switchModel(modelId);
    }
    
    // Cache the adapter if valid
    if (adapter != null && adapter.isInitialized) {
      _adapterCache[cacheKey] = adapter;
      _adapterCacheTime[cacheKey] = now;
      if (kDebugMode) print('DEBUG: Cached new adapter: $cacheKey');
      return adapter;
    }
    
    if (kDebugMode) print('DEBUG: No valid adapter found for provider+model: $cacheKey');
    return null;
  }

  /// Get the user's current selected model from UI
  Future<String?> _getCurrentUserSelectedModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedModel = prefs.getString('last_selected_model');
      if (kDebugMode) print('DEBUG: User current selected model: $selectedModel');
      return selectedModel;
    } catch (e) {
      if (kDebugMode) print('DEBUG: Error getting user selected model: $e');
      return null;
    }
  }

  /// Detect provider from model name (simplified version)
  String _detectProviderFromModel(String model) {
    if (model.toLowerCase().contains('gemini') || model.toLowerCase().contains('google')) {
      return 'google';
    } else if (model.toLowerCase().contains('gpt') || model.toLowerCase().contains('openai')) {
      return 'openai';
    } else if (model.toLowerCase().contains('glm') || model.toLowerCase().contains('zhipu')) {
      return 'zhipu-ai';
    }
    // Default to zhipu-ai for unknown models (can be removed if no fallback desired)
    return 'zhipu-ai';
  }

  Future<void> sendMessage(String text,
      {bool agentMode = false, bool swarmMode = false}) async {
    if (text.trim().isEmpty) return;

    final langchainUserMessage =
        langchain.ChatMessage.human(langchain.ChatMessageContent.text(text));
    final userMessage = convertLangchainChatMessage(langchainUserMessage);
    // Record start time for latency diagnostics
    final startTime = DateTime.now();

    // Add user message immediately
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // Insert a typing placeholder assistant message to improve perceived responsiveness.
    // This avoids the "dead air" while waiting for full model response since we currently
    // use non-streaming invoke(). We will later replace this placeholder with the final content.
    // NOTE: Real token streaming should use a streaming endpoint; this is a UX enhancement only.
    final placeholderId =
        'assistant_typing_${DateTime.now().millisecondsSinceEpoch}';
    final typingPlaceholder = micro.ChatMessage.typing(
      id: placeholderId,
      userId: 'ai',
    );
    _pendingTypingId = placeholderId;
    state = state.copyWith(
      messages: [...state.messages, typingPlaceholder],
      // Keep isLoading true
    );

    try {
      // NORMAL MODE: Use optimized provider adapter detection
      final adapter = await _getOptimizedAdapter();

      

      final finalAdapter = adapter;
      if (finalAdapter != null && finalAdapter.isInitialized) {
        print(
            'DEBUG: Using adapter: ${finalAdapter.providerId} with model: ${finalAdapter.currentModel}');

        // Use streaming if supported for real-time token display
        if (finalAdapter.supportsStreaming) {
          print('DEBUG: Using streaming for ${finalAdapter.providerId}');

          // Accumulate the complete response
          final buffer = StringBuffer();
          await for (final token in finalAdapter.sendMessageStream(
            text: text,
            history:
                state.messages.where((m) => m.id != placeholderId).toList(),
          )) {
            buffer.write(token);
          }

          // Create the complete assistant message
          final assistantId =
              'assistant_${DateTime.now().millisecondsSinceEpoch}';
          final completeResponse = buffer.toString();
          final assistantMessage = micro.ChatMessage.assistant(
            id: assistantId,
            content: completeResponse,
          );

          // Remove typing placeholder and add the complete assistant message
          final updatedMessages = [
            for (final m in state.messages)
              if (m.id != placeholderId) m,
          ];
          updatedMessages.add(assistantMessage);
          state = state.copyWith(messages: updatedMessages, isLoading: false);

          _logLatency(startTime, mode: 'streaming');
        } else {
          // Fallback to non-streaming (original behavior)
          print('DEBUG: Using non-streaming for ${finalAdapter.providerId}');
          final aiResponse = await finalAdapter.sendMessage(
            text: text,
            history: state.messages,
          );
          // Remove typing placeholder then append final message to avoid re-streaming
          // previous assistant messages (mutation caused prior duplicate animations).
          final updatedMessages = [
            for (final m in state.messages)
              if (m.id != placeholderId) m,
          ];
          updatedMessages.add(aiResponse);
          state = state.copyWith(messages: updatedMessages, isLoading: false);
          _logLatency(startTime, mode: 'normal');
        }
      } else {
        // Fallback response if no AI adapter is available
        final aiResponse = micro.ChatMessage.assistant(
          id: DateTime.now().toIso8601String(),
          content:
              'Sorry, no AI provider is currently available. Please configure an AI provider in settings.',
        );
        final updatedMessages = [
          for (final m in state.messages)
            if (m.id != placeholderId) m,
        ];
        updatedMessages.add(aiResponse);
        state = state.copyWith(messages: updatedMessages, isLoading: false);
        _logLatency(startTime, mode: 'no-adapter');
      }
    } catch (e) {
      print('DEBUG: Error in sendMessage: $e');
      print('DEBUG: Creating error message for rate limit');

      // Create an error message for the chat
      String errorMessage;
      if (e.toString().contains('RateLimitException') ||
          e.toString().contains('429')) {
        errorMessage =
            'I\'ve reached my usage limit for now. Please try again later or switch to a different AI provider in settings.';
      } else if (e.toString().contains('quota') ||
          e.toString().contains('billing')) {
        errorMessage =
            'The AI service quota has been exceeded. Please check your billing details or try a different provider.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Network connection issue. Please check your internet connection and try again.';
      } else {
        errorMessage =
            'Sorry, I encountered an error while processing your message. Please try again.';
      }

      print('DEBUG: Creating error message: $errorMessage');

      final errorResponse = micro.ChatMessage.error(
        id: DateTime.now().toIso8601String(),
        content: errorMessage,
      );

      final updatedMessages = [
        for (final m in state.messages)
          if (m.id != placeholderId) m,
      ];
      updatedMessages.add(errorResponse);
      state = state.copyWith(
          messages: updatedMessages, isLoading: false, error: e.toString());
      _logLatency(startTime, mode: 'error');
    }
  }

  /// Clear all messages from the chat history
  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  /// Simple latency logging helper
  void _logLatency(DateTime start, {required String mode}) {
    final elapsed = DateTime.now().difference(start);
    print('LATENCY [$mode]: ${elapsed.inMilliseconds} ms total');
  }
}
    final swarmStartTime = DateTime.now();
    final agentStart = DateTime.now();
    String result;
    agent_types.AgentResult? agentResult;
    try {
      print('DEBUG: Swarm mode - Executing with goal: $userMessage');

      // Initialize agent service if needed
      if (_agentService == null) {
        print('DEBUG: Initializing agent service for swarm');
        _agentService = AgentService(mcpService: _mcpService);
        await _agentService!.initialize();
      }

      // Get current LLM provider - respect user's selection
      final activeModels = _aiProviderConfig.getAllActiveModels();
      ProviderAdapter? adapter;

      // Use the first available provider (this respects the order of user preference)
      if (activeModels.isNotEmpty) {
        final firstProvider = activeModels.keys.first;
        adapter = await _aiProviderConfig.getProvider(firstProvider);
        print('DEBUG: Swarm using provider: $firstProvider with model: ${activeModels[firstProvider]}');
      }

      if (adapter == null) {
        throw Exception('No AI provider available for swarm execution');
      }

      // Get LangChain model from provider adapter for swarm execution
      final langChainModel = adapter.getLangChainModel();
      if (langChainModel == null) {
        throw Exception(
            'Provider ${adapter.providerId} does not support LangChain models required for Swarm');
      }

      // LLM-driven routing decision with heuristic fallback
      final routingStart = DateTime.now();
      SwarmRouteDecision route;
      
      try {
        route = await _llmSwarmRoutingDecision(langChainModel, userMessage);
      } catch (e) {
        print('DEBUG: Swarm routing failed completely: $e');
        // Fall back to heuristic routing
        route = _heuristicSwarmRouting(userMessage);
      }
      
      final routingDuration = DateTime.now().difference(routingStart);
      // SWARM_METRIC: captures LLM routing latency & decision outcome (observability for trivial vs complex goals)
      print(
          'SWARM_METRIC phase=routing duration_ms=${routingDuration.inMilliseconds} use_swarm=${route.useSwarm} max_specialists=${route.maxSpecialists ?? -1}');
      final useSwarm = route.useSwarm;
      final maxSpecialists = route.maxSpecialists;

      if (!useSwarm) {
        // Route directly to the adapter for a conversational response
        try {
          final aiResponse = await adapter.sendMessage(
            text: userMessage,
            history: state.messages,
          );

          // Remove typing placeholder if present
          final updatedMessages = [
            for (final m in state.messages)
              if (m.id != _pendingTypingId) m,
          ];
          updatedMessages.add(aiResponse);
          state = state.copyWith(messages: updatedMessages, isLoading: false);
          _pendingTypingId = null;
          print('DEBUG: Routed by LLM to direct response (no swarm)');
          return;
        } catch (e) {
          print('DEBUG: Direct response failed: $e');
          // Fall back to error handling below
        }
      }

      // Use LangChain Agent pattern like the clean example
      try {
        print('DEBUG: Starting LangChain agent execution');
        
        // Execute using LangChain AgentService (simple and clean)
        agentResult = await _agentService!.executeGoal(goal: userMessage).timeout(
          Duration(minutes: 2),
          onTimeout: () {
            throw Exception('Agent execution timed out after 2 minutes');
          },
        );
        
        // Extract the result from AgentResult
        result = agentResult.result;
        
        print('DEBUG: LangChain agent execution completed successfully');
      } catch (e) {
        print('DEBUG: LangChain agent execution failed: $e');
        
        // Create a fallback response for agent failures
        final fallbackResponse = '''🚫 **Agent Execution Failed**

I attempted to use multi-agent collaboration to handle your request, but encountered an issue: ${e.toString()}

**Alternative Approach:**
Let me help you with a standard AI response instead:

${await adapter.sendMessage(
          text: userMessage,
          history: state.messages,
        ).then((msg) => msg.content).catchError((_) => 'I apologize, but I\'m having trouble processing your request right now. Please try again.')}

*Tip: For complex tasks, try breaking them into smaller, specific questions for better results.*''';

        final fallbackMessage = micro.ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: fallbackResponse,
          type: micro.MessageType.assistant,
          timestamp: DateTime.now(),
          status: micro.MessageStatus.sent,
          userId: null,
          metadata: {},
          attachments: [],
          isEdited: false,
          editedAt: null,
          replyToId: null,
          readBy: [],
        );

        // Remove typing placeholder and add fallback message
        final updatedMessages = [
          for (final m in state.messages)
            if (m.id != _pendingTypingId) m,
          fallbackMessage,
        ];
        state = state.copyWith(messages: updatedMessages, isLoading: false);
        _pendingTypingId = null;
        return;
      }
      
      final agentExecDuration = DateTime.now().difference(agentStart);
      try {
        // LangChain agent metrics
        final stepsCount = agentResult.steps?.length ?? 0;
        final isSuccess = agentResult.success;
        // AGENT_METRIC: captures LangChain agent execution wall-clock latency & step count
        print(
            'AGENT_METRIC phase=agent_exec duration_ms=${agentExecDuration.inMilliseconds} steps_count=$stepsCount success=$isSuccess');
      } catch (_) {
        print(
            'AGENT_METRIC phase=agent_exec duration_ms=${agentExecDuration.inMilliseconds}');
      }

      // Validate result before formatting
      if (result == null) {
        throw Exception('Swarm execution returned null result');
      }

      // Format swarm response with better error handling
      final responseText = _formatSwarmResponseImproved(result);

      final langchainBotMessage = langchain.ChatMessage.ai(responseText);
      final botMessage = convertLangchainChatMessage(langchainBotMessage);

      // Remove typing placeholder then add final swarm message
      final updatedMessages = [
        for (final m in state.messages)
          if (m.id != _pendingTypingId) m,
      ];
      updatedMessages.add(botMessage);
      state = state.copyWith(messages: updatedMessages, isLoading: false);
      _pendingTypingId = null;

      print(
          'DEBUG: LangChain agent execution completed - ${agentResult.steps?.length ?? 0} steps');
    } catch (e, stackTrace) {
      final agentDuration = DateTime.now().difference(agentStart);
      print('DEBUG: LangChain agent execution error after ${agentDuration.inMilliseconds}ms: $e');
      print('DEBUG: Stack trace: $stackTrace');

      // Try fallback to direct chat when swarm fails
      try {
        print('DEBUG: Attempting fallback to direct chat due to swarm failure');
        
        // Get the first available adapter for fallback
        final activeModels = _aiProviderConfig.getAllActiveModels();
        ProviderAdapter? fallbackAdapter;
        
        for (final entry in activeModels.entries) {
          fallbackAdapter = await _aiProviderConfig.getProvider(entry.key);
          if (fallbackAdapter != null) break;
        }
        
        if (fallbackAdapter != null) {
          final fallbackResponse = await fallbackAdapter.sendMessage(
            text: userMessage,
            history: state.messages,
          );

          // Remove typing placeholder if present
          final updatedMessages = [
            for (final m in state.messages)
              if (m.id != _pendingTypingId) m,
          ];
          updatedMessages.add(fallbackResponse);
          state = state.copyWith(messages: updatedMessages, isLoading: false);
          _pendingTypingId = null;
          
          print('DEBUG: Successfully fell back to direct chat with ${fallbackAdapter.providerId}');
        } else {
          throw Exception('No providers available for fallback');
        }
      } catch (fallbackError) {
        print('DEBUG: Fallback also failed: $fallbackError');
        
        // Remove typing placeholder and show user-friendly error
        final updatedMessages = [
          for (final m in state.messages)
            if (m.id != _pendingTypingId) m,
        ];
        
        final errorMessage = micro.ChatMessage.assistant(
          id: DateTime.now().toIso8601String(),
          content: 'I encountered an issue with my advanced processing mode. Let me try a simpler approach. Could you please rephrase your request?'
        );
        
        updatedMessages.add(errorMessage);
        state = state.copyWith(messages: updatedMessages, isLoading: false);
        _pendingTypingId = null;
      }
    }
  }

  /// LLM-driven swarm routing decision. Returns a compact decision without any hardcoded heuristics.
  Future<SwarmRouteDecision> _llmSwarmRoutingDecision(
    BaseChatModel model,
    String goal,
  ) async {
    try {
      final system = langchain.ChatMessage.system('''
You are a routing controller. Decide if the user's request requires multi-agent swarm planning (multiple specialists, tool usage, decomposition) or a single direct conversational response.
Return ONLY compact JSON with these fields and nothing else:
{
  "use_swarm": true|false,
  "reason": "short reason",
  "max_specialists": integer  
}
If the request is simple chit-chat or can be answered directly without planning/tools, set use_swarm to false. Do not include markdown fences or explanations.
''');

      final human = langchain.ChatMessage.human(langchain.ChatMessageContent.text('''
USER_GOAL:
$goal
'''));

      final response = await model.invoke(PromptValue.chat([system, human]));
      
      // Defensive check for null response
      if (response == null) {
        print('DEBUG: Null response from routing model');
        return SwarmRouteDecision(useSwarm: false, maxSpecialists: null);
      }
      
      // Extract content as String - simplified and type-safe
      String text = '';
      final output = response.output;
      
      if (output == null) {
        print('DEBUG: Response output is null');
      } else if (output is langchain.AIChatMessage) {
        // AIChatMessage.content is ChatMessageContent, not String - extract safely
        final content = output.content;
        if (content == null) {
          print('DEBUG: AIChatMessage content is null');
          text = '';
        } else if (content is String) {
          text = content;
        } else {
          text = content.toString();
        }
      } else if (output is langchain.SystemChatMessage) {
        // SystemChatMessage.content is ChatMessageContent, not String - extract safely
        final content = output.content;
        if (content == null) {
          print('DEBUG: SystemChatMessage content is null');
          text = '';
        } else if (content is String) {
          text = content;
        } else {
          text = content.toString();
        }
      } else if (output is langchain.HumanChatMessage) {
        // HumanChatMessage.content is ChatMessageContent, convert to string
        final content = output.content;
        if (content == null) {
          print('DEBUG: HumanChatMessage content is null');
          text = '';
        } else if (content is String) {
          text = content;
        } else {
          text = content.toString();
        }
      } else {
        // Fallback to toString for unknown types
        print('DEBUG: Unknown output type: ${output.runtimeType}');
        text = output.toString();
      }
      
      if (text.isEmpty) {
        print('DEBUG: Empty response from routing model, defaulting to direct chat');
        return SwarmRouteDecision(useSwarm: false, maxSpecialists: null);
      }

      if (kDebugMode) {
        print('DEBUG: Swarm routing response: $text');
      }

      String jsonText = text.trim();
      final match = RegExp(r"\{[\s\S]*\}").firstMatch(jsonText);
      if (match != null) {
        jsonText = match.group(0)!;
      }

      try {
        // Additional validation before JSON parsing
        if (jsonText.isEmpty || !jsonText.startsWith('{')) {
          throw FormatException('Response does not appear to be JSON');
        }
        
        final parsed = json.decode(jsonText) as Map<String, dynamic>?;
        
        // Validate parsing result
        if (parsed == null) {
          throw FormatException('JSON parsing returned null');
        }
        
        // Validate required fields exist
        if (!parsed.containsKey('use_swarm')) {
          throw FormatException('Missing required field: use_swarm');
        }
        
        // Safely extract values with proper type checking
        final useSwarmValue = parsed['use_swarm'];
        final use = useSwarmValue == true;
        
        final max = parsed['max_specialists'];
        final maxInt = max is num ? max.toInt() : null;
        
        if (kDebugMode) {
          print('DEBUG: Swarm routing decision: useSwarm=$use, maxSpecialists=$maxInt');
        }
        
        return SwarmRouteDecision(useSwarm: use, maxSpecialists: maxInt);
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG: Failed to parse swarm routing JSON: $e');
          print('DEBUG: Original response: $text');
          print('DEBUG: Extracted JSON text: $jsonText');
        }
        // If parsing fails, default to NOT using swarm for reliability
        return SwarmRouteDecision(useSwarm: false, maxSpecialists: null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Swarm routing failed completely: $e');
      }
      // If everything fails, default to direct chat
      return SwarmRouteDecision(useSwarm: false, maxSpecialists: null);
    }
  }

  /// Heuristic swarm routing as fallback when LLM routing fails
  SwarmRouteDecision _heuristicSwarmRouting(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Complex indicators that suggest swarm collaboration
    final complexIndicators = [
      'analyze', 'comprehensive', 'strategy', 'implement', 'design', 'optimize',
      'create a system', 'build', 'develop', 'architecture', 'framework',
      'multiple', 'various', 'several', 'integrate', 'coordinate', 'manage'
    ];
    
    // Domain indicators that suggest multiple specialists
    final domainIndicators = [
      'performance', 'security', 'user experience', 'database', 'api',
      'testing', 'deployment', 'monitoring', 'analytics', 'infrastructure'
    ];
    
    // Simple task indicators that don't need swarm
    final simpleIndicators = [
      'what is', 'tell me', 'explain', 'define', 'example', 'how to',
      'can you', 'could you', 'would you', 'thank', 'hello', 'hi'
    ];
    
    // Count matches
    int complexScore = 0;
    int domainScore = 0;
    int simpleScore = 0;
    
    for (final indicator in complexIndicators) {
      if (message.contains(indicator)) complexScore++;
    }
    
    for (final indicator in domainIndicators) {
      if (message.contains(indicator)) domainScore++;
    }
    
    for (final indicator in simpleIndicators) {
      if (message.contains(indicator)) simpleScore++;
    }
    
    // Decision logic
    final totalScore = complexScore + (domainScore * 2);
    final shouldUseSwarm = totalScore >= 2 && simpleScore == 0 && message.length > 50;
    
    final maxSpecialists = shouldUseSwarm ? (domainScore + 1).clamp(1, 4) : null;
    
    print('DEBUG: Heuristic routing - complexScore: $complexScore, domainScore: $domainScore, simpleScore: $simpleScore');
    print('DEBUG: Heuristic decision - useSwarm: $shouldUseSwarm, maxSpecialists: $maxSpecialists');
    
    return SwarmRouteDecision(
      useSwarm: shouldUseSwarm,
      maxSpecialists: maxSpecialists,
    );
  }

  /// Format swarm result for display
  /// Improved swarm response formatting with better error handling
  String _formatSwarmResponseImproved(dynamic swarmResult) {
    try {
      final buffer = StringBuffer();

      buffer.writeln('🤖 **Swarm Intelligence Analysis**\n');
      
      // Safely extract metrics with null checks
      try {
        final specialistsUsed = swarmResult?.totalSpecialistsUsed ?? 0;
        final duration = swarmResult?.totalDuration?.inSeconds ?? 0;
        final cost = swarmResult?.estimatedCost?.toStringAsFixed(4) ?? '0.0000';
        
        buffer.writeln('Specialists used: $specialistsUsed');
        buffer.writeln('Duration: ${duration}s');
        buffer.writeln('Estimated cost: \$$cost\n');
      } catch (e) {
        buffer.writeln('Metrics unavailable\n');
      }

      // Check for errors
      try {
        final error = swarmResult?.error;
        if (error != null && error.toString().isNotEmpty) {
          buffer.writeln('⚠️ Planning error encountered: $error');
          buffer.writeln('Fallback specialist used. Results may be limited.\n');
        }
      } catch (e) {
        // Ignore error extraction issues
      }

      // Try to get the main answer first
      try {
        final finalAnswer = swarmResult?.finalAnswer;
        if (finalAnswer != null && finalAnswer.toString().isNotEmpty) {
          buffer.writeln('**Answer:**\n$finalAnswer\n');
          return buffer.toString(); // Early return if we have a good answer
        }
      } catch (e) {
        // Continue to other formatting options
      }

      // Fallback to blackboard facts
      buffer.writeln('### Findings:\n');

      try {
        final facts = swarmResult?.blackboard?.getAllFacts() ?? {};
        
        // Check for clarification needs
        final needsClar = facts['clarification_needed'] == true;
        if (needsClar) {
          buffer.writeln('📝 **Clarification Required Before Planning**');
          final reason = facts['clarification_reason']?.toString();
          if (reason != null && reason.isNotEmpty) {
            buffer.writeln('- Reason: $reason');
          }
          final questions = facts['clarification_questions'];
          if (questions is List && questions.isNotEmpty) {
            buffer.writeln('\nPlease answer the following to proceed:');
            for (int i = 0; i < questions.length; i++) {
              buffer.writeln('${i + 1}. ${questions[i]}');
            }
          }
          buffer.writeln('\nAfter answering, re-submit your goal to continue with specialist planning.');
          buffer.writeln('\n---');
        }

        // Display key facts
        if (facts.isNotEmpty) {
          for (final entry in facts.entries) {
            if (entry.key != 'clarification_needed' && 
                entry.key != 'clarification_reason' && 
                entry.key != 'clarification_questions') {
              buffer.writeln('**${entry.key}**: ${entry.value}');
            }
          }
        } else {
          buffer.writeln('No detailed findings available.');
        }
      } catch (e) {
        buffer.writeln('Unable to extract detailed findings.');
      }

      // Add status information
      try {
        final specialistsUsed = swarmResult?.totalSpecialistsUsed ?? 0;
        final error = swarmResult?.error;
        final converged = swarmResult?.converged ?? false;
        
        if (specialistsUsed == 0 && error != null) {
          buffer.writeln('\n⚠️ No specialists executed due to planning failure. Try re-running or using a different model.');
        } else if (converged) {
          buffer.writeln('\n✅ Goal achieved with high confidence');
        } else {
          buffer.writeln('\n⚠️ Partial completion - some objectives may require further analysis');
        }
      } catch (e) {
        buffer.writeln('\nStatus information unavailable');
      }

      buffer.writeln('\n*This response was generated using multi-agent intelligence collaboration.*');
      return buffer.toString();
    } catch (e) {
      // Ultimate fallback if everything fails
      return '''🤖 **Swarm Intelligence Analysis**

I attempted to analyze your request using multi-agent collaboration, but encountered formatting issues.

**Error details:** $e

**Suggestion:** Please try rephrasing your request or break it down into smaller, more specific questions.

*You can also try switching between Swarm AI and Direct Chat modes in the settings.*''';
    }
  }

  /// Legacy swarm response formatting (kept for compatibility)
  String _formatSwarmResponse(dynamic swarmResult) {
    return _formatSwarmResponseImproved(swarmResult);
  }

  /// Execute agent mode with MCP tools
  Future<void> _executeAgentMode(String userMessage) async {
    try {
      // Get enabled MCP server IDs (only connected servers)
      final mcpServerIds = _getEnabledMCPServerIds();

      print('DEBUG: Agent mode - Using MCP servers: $mcpServerIds');

      // Create agent with MCP tools
      final agentId = await _agentService!.createAgent(
        name: 'Micro',
        mcpServerIds: mcpServerIds.isNotEmpty ? mcpServerIds : null,
      );

      // Execute agent with user's query
      final result = await _agentService!.executeGoal(
        goal: userMessage,
        agentId: agentId,
      );

      // Add agent response with tool execution steps
      _addAgentResponseWithSteps(result);
    } catch (e, stackTrace) {
      print('DEBUG: Agent execution error: $e');
      print('DEBUG: Stack trace: $stackTrace');

      state = state.copyWith(
        error: 'Agent execution failed: $e',
        isLoading: false,
      );
    }
  }

  /// Get list of enabled (connected) MCP server IDs
  List<String> _getEnabledMCPServerIds() {
    if (_mcpService == null) return [];

    final configs = _mcpService!.getServerConfigs();
    final enabledServers = <String>[];

    for (final config in configs) {
      final state = _mcpService!.getServerState(config.id);
      if (state != null && state.status == MCPConnectionStatus.connected) {
        enabledServers.add(config.id);
      }
    }

    return enabledServers;
  }

  /// Add agent response with tool execution steps to chat
  void _addAgentResponseWithSteps(agent_types.AgentResult result) {
    // Format agent response with tool steps
    final stepsText = StringBuffer();

    if (result.steps.isNotEmpty) {
      stepsText.writeln('\n---\n**Execution Steps:**\n');

      for (var i = 0; i < result.steps.length; i++) {
        final step = result.steps[i];
        stepsText.writeln('${i + 1}. ${step.type.name}: ${step.description}');

        if (step.input != null) {
          stepsText.writeln('   Input: ${step.input}');
        }
        if (step.output != null) {
          stepsText.writeln('   Output: ${step.output}');
        }
        if (step.duration.inMilliseconds > 0) {
          stepsText.writeln('   Duration: ${step.duration.inMilliseconds}ms');
        }
      }
    }

    final fullResponse = result.result + stepsText.toString();

    // Convert to chat message format
    final langchainAssistantMessage = langchain.ChatMessage.ai(fullResponse);
    final assistantMessage =
        convertLangchainChatMessage(langchainAssistantMessage);

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      isLoading: false,
      error: null,
    );
  }
}

// NOTE: Removed _SwarmLanguageModelAdapter due to type mismatch with
// AgentService.executeSwarmGoal. See _executeSwarmMode for details.

/// Simple latency logging helper
void _logLatency(DateTime start, {required String mode}) {
  final elapsed = DateTime.now().difference(start);
  print('LATENCY [$mode]: ${elapsed.inMilliseconds} ms total');
}
