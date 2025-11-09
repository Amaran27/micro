import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langchain/langchain.dart';
import 'package:micro/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:micro/infrastructure/ai/ai_provider_config.dart';
import 'package:micro/infrastructure/ai/interfaces/provider_adapter.dart';
import 'package:micro/infrastructure/ai/interfaces/provider_config.dart' as pc;
import 'package:micro/infrastructure/ai/adapters/zhipuai_adapter.dart';
import 'package:micro/infrastructure/ai/adapters/chat_google_adapter.dart';
import 'package:micro/infrastructure/ai/adapters/chat_openai_adapter.dart';
import 'package:micro/features/chat/data/sources/llm_data_source.dart';
import 'package:micro/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:micro/features/chat/domain/utils/chat_message_converter.dart';
import 'package:micro/infrastructure/ai/model_selection_service.dart';
import 'package:micro/core/utils/logger.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;


import 'package:micro/infrastructure/ai/mcp/mcp_service.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';
import 'package:micro/infrastructure/ai/agent/agent_service.dart';
import 'package:micro/infrastructure/ai/agent/agent_types.dart' as agent_types;
import 'dart:convert';

/// Routing decision returned by LLM classification for swarm usage.
class SwarmRouteDecision {
  final bool useSwarm;
  final int? maxSpecialists;
  const SwarmRouteDecision({required this.useSwarm, this.maxSpecialists});
}

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
  
  MCPService? _mcpService;
  AgentService? _agentService;
  String? _pendingTypingId;

  ChatNotifier(this._aiProviderConfig, this._ref) : super(ChatState()) {
    _initializeAIProvider();
    _initializeAgentServices();
  }

  Future<void> _initializeAIProvider() async {
    // Only initialize once, check if already initialized
    if (!_aiProviderConfig.isInitialized) {
      await _aiProviderConfig.initialize();
    }
  }

  void _initializeAgentServices() {
    // Initialize MCP and Agent services
    _mcpService = MCPService();
    _agentService = AgentService(mcpService: _mcpService!);
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
        ChatMessage.human(ChatMessageContent.text(text));
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
      // SWARM MODE: Use swarm intelligence for complex tasks
      if (swarmMode && _agentService != null) {
        await _executeSwarmMode(text);
        _logLatency(startTime, mode: 'swarm');
        return;
      }

      // AGENT MODE: Use autonomous agent with MCP tools
      if (agentMode && _agentService != null) {
        await _executeAgentMode(text);
        _logLatency(startTime, mode: 'agent');
        return;
      }

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

  /// Create adapter from new ProviderConfig
  Future<ProviderAdapter?> _createAdapterFromConfig(
      dynamic config, String modelId) async {
    try {
      final providerId = config.providerId;
      final apiKey = config.apiKey;

      print('DEBUG: Creating adapter for $providerId with model $modelId');

      ProviderAdapter? adapter;

      switch (providerId) {
        case 'zhipu-ai':
          adapter = ZhipuAIAdapter();
          final zhipuConfig = pc.ZhipuAIConfig(
            model: modelId,
            apiKey: apiKey,
          );
          await adapter.initialize(zhipuConfig);
          break;
        case 'google':
          adapter = ChatGoogleAdapter();
          final googleConfig = pc.GoogleConfig(
            model: modelId,
            apiKey: apiKey,
          );
          await adapter.initialize(googleConfig);
          break;
        case 'openai':
          adapter = ChatOpenAIAdapter();
          final openaiConfig = pc.OpenAIConfig(
            model: modelId,
            apiKey: apiKey,
          );
          await adapter.initialize(openaiConfig);
          break;
        default:
          print(
              'DEBUG: Provider $providerId not yet implemented for new system');
          return null;
      }

      print(
          'DEBUG: Successfully created and initialized adapter for $providerId');
      return adapter;
    } catch (e) {
      print('DEBUG: Error creating adapter from config: $e');
      return null;
    }
  }

  

  /// Execute swarm mode with multiple specialists
  Future<void> _executeSwarmMode(String userMessage) async {
    try {
      print('DEBUG: Swarm mode - Executing with goal: $userMessage');

      // Initialize agent service if needed
      if (_agentService == null) {
        print('DEBUG: Initializing agent service for swarm');
        _agentService = AgentService(mcpService: _mcpService);
        await _agentService!.initialize();
      }

      // Get current LLM provider
      final activeModels = _aiProviderConfig.getAllActiveModels();
      ProviderAdapter? adapter;

      // Try ZhipuAI first, then others
      final zhipuaiModel = activeModels['zhipu-ai'];
      if (zhipuaiModel != null) {
        adapter = await _aiProviderConfig.getProvider('zhipu-ai');
      } else {
        for (final entry in activeModels.entries) {
          adapter = await _aiProviderConfig.getProvider(entry.key);
          if (adapter != null) break;
        }
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

      // LLM-driven routing decision (no regex/hardcoding): decide whether to use swarm
      final routingStart = DateTime.now();
      final route = await _llmSwarmRoutingDecision(langChainModel, userMessage);
      final routingDuration = DateTime.now().difference(routingStart);
      // SWARM_METRIC: captures LLM routing latency & decision outcome (observability for trivial vs complex goals)
      print(
          'SWARM_METRIC phase=routing duration_ms=${routingDuration.inMilliseconds} use_swarm=${route.useSwarm} max_specialists=${route.maxSpecialists ?? -1}');
      final useSwarm = route.useSwarm;
      final maxSpecialists = route.maxSpecialists;

      if (!useSwarm) {
        // Route directly to the adapter for a conversational response
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
      }

      // Execute swarm with user's selected model
      final swarmStart = DateTime.now();
      final result = await _agentService!.executeSwarmGoal(
        goal: userMessage,
        languageModel: langChainModel,
        maxSpecialists: maxSpecialists,
      );
      final swarmExecDuration = DateTime.now().difference(swarmStart);
      try {
        // best-effort metrics: relies on SwarmResult-like shape
        final specialistsUsed = result.totalSpecialistsUsed;
        final totalSecs = result.totalDuration.inSeconds;
        // SWARM_METRIC: captures full swarm execution wall-clock latency & utilization footprint
        print(
            'SWARM_METRIC phase=swarm_exec duration_ms=${swarmExecDuration.inMilliseconds} specialists_used=$specialistsUsed result_duration_s=$totalSecs');
      } catch (_) {
        print(
            'SWARM_METRIC phase=swarm_exec duration_ms=${swarmExecDuration.inMilliseconds}');
      }

      // Format swarm response
      final responseText = _formatSwarmResponse(result);

      final langchainBotMessage = ChatMessage.ai(responseText);
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
          'DEBUG: Swarm execution completed - ${result.totalSpecialistsUsed} specialists');
    } catch (e, stackTrace) {
      print('DEBUG: Swarm execution error: $e');
      print('DEBUG: Stack trace: $stackTrace');

      state = state.copyWith(
        error: 'Swarm execution failed: $e',
        isLoading: false,
      );
    }
  }

  /// LLM-driven swarm routing decision. Returns a compact decision without any hardcoded heuristics.
  Future<SwarmRouteDecision> _llmSwarmRoutingDecision(
    BaseChatModel model,
    String goal,
  ) async {
    final system = ChatMessage.system('''
You are a routing controller. Decide if the user's request requires multi-agent swarm planning (multiple specialists, tool usage, decomposition) or a single direct conversational response.
Return ONLY compact JSON with these fields and nothing else:
{
  "use_swarm": true|false,
  "reason": "short reason",
  "max_specialists": integer  
}
If the request is simple chit-chat or can be answered directly without planning/tools, set use_swarm to false. Do not include markdown fences or explanations.
''');

    final human = ChatMessage.human(ChatMessageContent.text('''
USER_GOAL:
$goal
'''));

    final response = await model.invoke(PromptValue.chat([system, human]));
    final text = response.output.content.toString();

    String jsonText = text.trim();
    final match = RegExp(r"\{[\s\S]*\}").firstMatch(jsonText);
    if (match != null) {
      jsonText = match.group(0)!;
    }

    try {
      final parsed = json.decode(jsonText) as Map<String, dynamic>;
      final use = parsed['use_swarm'] == true;
      final max = parsed['max_specialists'];
      final maxInt = max is num ? max.toInt() : null;
      return SwarmRouteDecision(useSwarm: use, maxSpecialists: maxInt);
    } catch (_) {
      // If parsing fails, default to using swarm to preserve functionality
      return SwarmRouteDecision(useSwarm: true, maxSpecialists: null);
    }
  }

  /// Format swarm result for display
  String _formatSwarmResponse(dynamic swarmResult) {
    final buffer = StringBuffer();

    buffer.writeln('🤖 **Swarm Intelligence Analysis**\n');
    buffer.writeln('Specialists used: ${swarmResult.totalSpecialistsUsed}');
    buffer.writeln('Duration: ${swarmResult.totalDuration.inSeconds}s');
    buffer.writeln(
        'Estimated cost: \$${swarmResult.estimatedCost.toStringAsFixed(4)}\n');

    if (swarmResult.error != null && swarmResult.error!.isNotEmpty) {
      buffer.writeln('⚠️ Planning error encountered: ${swarmResult.error}');
      buffer.writeln('Fallback specialist used. Results may be limited.\n');
    }

    buffer.writeln('### Findings:\n');

    // Get all facts from blackboard
    final facts = swarmResult.blackboard.getAllFacts();

    // Clarification-first rendering: if clarification needed, surface questions prominently
    try {
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
        buffer.writeln(
            '\nAfter answering, re-submit your goal to continue with specialist planning.');
        buffer.writeln('\n---');
      }
    } catch (_) {
      // Safe ignore if unexpected data shape
    }

    for (final entry in facts.entries) {
      buffer.writeln('**${entry.key}**: ${entry.value}');
    }

    if (swarmResult.totalSpecialistsUsed == 0 && swarmResult.error != null) {
      buffer.writeln(
          '\n⚠️ No specialists executed due to planning failure. Try re-running or using a different model.');
    } else if (swarmResult.converged) {
      buffer.writeln('\n✅ Goal achieved with high confidence');
    } else {
      buffer.writeln(
          '\n⚠️ Partial completion - some objectives may require further analysis');
    }

    return buffer.toString();
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
    final langchainAssistantMessage = ChatMessage.ai(fullResponse);
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
