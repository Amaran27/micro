import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/presentation/providers/provider_config_providers.dart';
import 'package:micro/infrastructure/ai/provider_config_model.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_service.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';
import 'package:micro/infrastructure/ai/agent/agent_service.dart';
import 'package:micro/infrastructure/ai/agent/agent_types.dart' as agent_types;
import 'package:micro/infrastructure/ai/agent/plan_execute_agent.dart';

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
  MCPService? _mcpService;
  AgentService? _agentService;

  ChatNotifier(this._aiProviderConfig, this._ref) : super(ChatState()) {
    _initializeAIProvider();
    _initializeAgentServices();
  }

  Future<void> _initializeAIProvider() async {
    await _aiProviderConfig.initialize();
  }

  void _initializeAgentServices() {
    // Initialize MCP and Agent services
    _mcpService = MCPService();
    _agentService = AgentService(mcpService: _mcpService!);
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

      // NORMAL MODE: Use existing provider adapters
      // Use active models from provider config instead of deleted model_selection_notifier
      final currentModelId = null; // No specific model selected yet
      print('DEBUG: Using active models from provider config');

      ProviderAdapter? adapter;

      // Try to get the active model for each provider
      final activeModels = _aiProviderConfig.getAllActiveModels();
      print('DEBUG: Active models: $activeModels');

      // Check if ZhipuAI has an active model
      final zhipuaiModel = activeModels['zhipu-ai'];
      if (zhipuaiModel != null) {
        adapter = _aiProviderConfig.getProvider('zhipu-ai');
        print('DEBUG: Using active ZhipuAI model: $zhipuaiModel');
      }

      // If no ZhipuAI model, try other providers
      if (adapter == null) {
        for (final entry in activeModels.entries) {
          final providerId = entry.key;
          final modelId = entry.value;
          print('DEBUG: Trying provider: $providerId with model: $modelId');

          adapter = _aiProviderConfig.getProvider(providerId);
          if (adapter != null) {
            print('DEBUG: Using provider: $providerId');
            break;
          }
        }
      }

      if (currentModelId != null) {
        // Get the provider for the selected model
        String providerId = _detectProviderFromModel(currentModelId);

        print(
            'DEBUG: Current model ID: $currentModelId, detected provider: $providerId');

        // First try to get adapter from new provider system
        try {
          final configsAsync = _ref.read(providersConfigProvider);
          final configs = await configsAsync.when(
            data: (data) async => data,
            loading: () async => [],
            error: (e, s) async {
              print('DEBUG: Error reading new configs: $e');
              return [];
            },
          );

          if (configs.isNotEmpty) {
            try {
              // Find config for this provider that has this model
              ProviderConfig? matchingConfig;

              // First try to find a config with the exact model as favorite
              for (final c in configs) {
                if (c.providerId == providerId &&
                    c.isEnabled &&
                    c.testPassed &&
                    c.favoriteModels.contains(currentModelId)) {
                  matchingConfig = c;
                  break;
                }
              }

              // If not found, try to find any enabled config for this provider
              if (matchingConfig == null) {
                for (final c in configs) {
                  if (c.providerId == providerId && c.isEnabled) {
                    matchingConfig = c;
                    break;
                  }
                }
              }

              if (matchingConfig != null) {
                print(
                    'DEBUG: Found new provider config: ${matchingConfig.providerId}');

                // Create adapter for this provider
                adapter = await _createAdapterFromConfig(
                    matchingConfig, currentModelId);
                print(
                    'DEBUG: Created adapter from new config: ${adapter?.providerId}');
              } else {
                print(
                    'DEBUG: No matching config found for provider: $providerId');
              }
            } catch (e) {
              print('DEBUG: Error finding config: $e');
            }
          }
        } catch (e) {
          print('DEBUG: Error reading new provider configs: $e');
        }

        // Fallback to old system if new system didn't provide adapter
        if (adapter == null) {
          adapter = _aiProviderConfig.getProvider(providerId);
          print(
              'DEBUG: Fallback to old provider system adapter: ${adapter?.providerId}');
        }

        print(
            'DEBUG: Final adapter: ${adapter?.providerId}, current model: ${adapter?.currentModel}');

        // If we couldn't get an adapter or it doesn't have the right model, try direct provider lookup
        if (adapter == null || adapter.currentModel != currentModelId) {
          if (currentModelId.toLowerCase().startsWith('glm-')) {
            adapter = _aiProviderConfig.getProvider('zhipu-ai');
            print('DEBUG: Using direct ZhipuAI provider for GLM model');
          } else if (currentModelId.toLowerCase().startsWith('gemini-')) {
            adapter = _aiProviderConfig.getProvider('google');
            print('DEBUG: Using direct Google provider for Gemini model');
          }
        }

        // Switch to the selected model if different from current
        final currentAdapter = adapter;
        if (currentAdapter != null &&
            currentAdapter.currentModel != currentModelId) {
          await currentAdapter.switchModel(currentModelId);
          print('DEBUG: Switched adapter to model: $currentModelId');
        }
      }

      // Fallback to any available provider if we couldn't get a specific one
      if (adapter == null) {
        // If no specific model is selected, try to use the active ZhipuAI model
        if (currentModelId == null) {
          final activeModels = _aiProviderConfig.getAllActiveModels();
          print('DEBUG: Active models when no currentModelId: $activeModels');

          // Check if ZhipuAI has an active model
          final zhipuaiModel = activeModels['zhipuai'];
          if (zhipuaiModel != null) {
            adapter = _aiProviderConfig.getProvider('zhipuai');
            print('DEBUG: Using active ZhipuAI model: $zhipuaiModel');
          } else {
            // Try Google as fallback
            final googleModel = activeModels['google'];
            if (googleModel != null) {
              adapter = _aiProviderConfig.getProvider('google');
              print('DEBUG: Using active Google model: $googleModel');
            }
          }
        }
        // Otherwise try to get a provider based on the current model prefix
        else if (currentModelId.toLowerCase().startsWith('glm-')) {
          adapter = _aiProviderConfig.getProvider('zhipuai');
          print(
              'DEBUG: Fallback to ZhipuAI adapter for GLM model: $currentModelId');
        } else if (currentModelId.toLowerCase().startsWith('gemini-')) {
          adapter = _aiProviderConfig.getProvider('google');
          print(
              'DEBUG: Using Google adapter for Gemini model: $currentModelId');
        } else {
          // For any other model, try to detect the provider
          final detectedProvider = _detectProviderFromModel(currentModelId);
          adapter = _aiProviderConfig.getProvider(detectedProvider);
          print(
              'DEBUG: Using detected provider $detectedProvider for model: $currentModelId');
        }
      }

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

  /// Detect provider from model ID
  String _detectProviderFromModel(String? modelId) {
    if (modelId == null) return 'google'; // Default fallback

    final lowerModelId = modelId.toLowerCase();

    // OpenAI models
    if (lowerModelId.startsWith('gpt-') ||
        lowerModelId.startsWith('o1-') ||
        lowerModelId.startsWith('dall-') ||
        lowerModelId.startsWith('whisper-') ||
        lowerModelId.startsWith('tts-')) {
      return 'openai';
    }

    // Anthropic Claude models
    if (lowerModelId.startsWith('claude-')) {
      return 'claude';
    }

    // Google models
    if (lowerModelId.startsWith('gemini-') ||
        lowerModelId.startsWith('palm-') ||
        lowerModelId.startsWith('bard-')) {
      return 'google';
    }

    // ZhipuAI models
    if (lowerModelId.startsWith('glm-') ||
        lowerModelId.startsWith('chatglm-')) {
      return 'zhipu-ai';
    }

    // Cohere models
    if (lowerModelId.startsWith('command-') ||
        lowerModelId.startsWith('base-') ||
        lowerModelId.startsWith('embed-')) {
      return 'cohere';
    }

    // Mistral models
    if (lowerModelId.startsWith('mistral-') ||
        lowerModelId.startsWith('codestral')) {
      return 'mistral';
    }

    // Stability AI models
    if (lowerModelId.contains('stable-diffusion') ||
        lowerModelId.contains('sdxl')) {
      return 'stability';
    }

    // Default to Google for unknown models
    return 'google';
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
        adapter = _aiProviderConfig.getProvider('zhipu-ai');
      } else {
        for (final entry in activeModels.entries) {
          adapter = _aiProviderConfig.getProvider(entry.key);
          if (adapter != null) break;
        }
      }

      if (adapter == null) {
        throw Exception('No AI provider available for swarm execution');
      }

      // Execute swarm using AgentService's internal default model.
      // NOTE: Previously we attempted to wrap ProviderAdapter with a custom
      // _SwarmLanguageModelAdapter and pass it as `languageModel` to
      // executeSwarmGoal. That parameter expects a BaseChatModel from LangChain,
      // not an arbitrary LanguageModel implementation. Passing the wrapper
      // produced a runtime type error:
      //   type '_SwarmLanguageModelAdapter' is not a subtype of type
      //   'BaseChatModel<ChatModelOptions>?'
      // To keep swarm mode stable, we now omit the languageModel argument so
      // AgentService falls back to its internally created default model. A
      // future enhancement could add an official BaseChatModel exposure from
      // ProviderAdapter to allow provider-selected models in swarm mode.
      final result = await _agentService!.executeSwarmGoal(
        goal: userMessage,
      );

      // Format swarm response
      final responseText = _formatSwarmResponse(result);

      final langchainBotMessage = ChatMessage.ai(responseText);
      final botMessage = convertLangchainChatMessage(langchainBotMessage);

      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );

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

  /// Format swarm result for display
  String _formatSwarmResponse(dynamic swarmResult) {
    final buffer = StringBuffer();

    buffer.writeln('🤖 **Swarm Intelligence Analysis**\n');
    buffer.writeln('Specialists used: ${swarmResult.totalSpecialistsUsed}');
    buffer.writeln('Duration: ${swarmResult.totalDuration.inSeconds}s');
    buffer.writeln(
        'Estimated cost: \$${swarmResult.estimatedCost.toStringAsFixed(4)}\n');

    buffer.writeln('### Findings:\n');

    // Get all facts from blackboard
    final facts = swarmResult.blackboard.getAllFacts();
    for (final entry in facts.entries) {
      buffer.writeln('**${entry.key}**: ${entry.value}');
    }

    if (swarmResult.converged) {
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
