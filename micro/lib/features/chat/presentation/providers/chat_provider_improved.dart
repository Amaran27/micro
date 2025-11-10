import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../../domain/entities/chat_message.dart';
import '../../../../../domain/entities/swarm_route_decision.dart';
import '../../../../../infrastructure/ai/agent/agent_service.dart';
import '../../../../../infrastructure/ai/models/current_model.dart';
import '../../../../../infrastructure/ai/providers/ai_provider_factory.dart';
import '../../../../../presentation/providers/current_selected_model_provider.dart';
import '../../../../../presentation/providers/enabled_providers_provider.dart';

/// Improved ChatNotifier with better swarm functionality
class ImprovedChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final AgentService _agentService;
  final List<ChatMessage> _messages = [];

  ImprovedChatNotifier(this._ref, this._agentService) : super(const ChatState.initial());

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Improved sendMessage with better swarm handling
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    
    state = ChatState.loading(_messages);
    
    try {
      // Get current AI model
      final currentModel = _ref.read(currentSelectedModelProvider);
      if (currentModel == null) {
        throw Exception('No AI model selected');
      }
      
      // Create chat model
      final chatModel = await _createChatModel(currentModel);
      
      // Check if we should use swarm mode
      final shouldUseSwarm = await _shouldUseSwarm(chatModel, message);
      
      String response;
      if (shouldUseSwarm) {
        response = await _executeSwarmModeImproved(message);
      } else {
        response = await _executeDirectChat(chatModel, message);
      }
      
      // Add AI response
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        type: ChatMessageType.assistant,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
      
      state = ChatState.loaded(_messages);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Error: ${e.toString()}',
        type: ChatMessageType.assistant,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
      
      state = ChatState.error(_messages, e.toString());
    }
  }

  /// Improved swarm routing decision with heuristic fallback
  Future<bool> _shouldUseSwarm(BaseChatModel model, String goal) async {
    // First, use simple heuristic routing
    final heuristicDecision = _simpleSwarmRouting(goal);
    if (kDebugMode) {
      print('DEBUG: Heuristic routing: useSwarm=${heuristicDecision.useSwarm}');
    }
    
    // If heuristic clearly says no swarm, don't bother with LLM
    if (!heuristicDecision.useSwarm && heuristicDecision.reason == 'simple_conversation') {
      return false;
    }
    
    // Try LLM routing for nuanced decisions
    try {
      final llmDecision = await _llmSwarmRoutingDecision(model, goal);
      if (kDebugMode) {
        print('DEBUG: LLM routing: useSwarm=${llmDecision.useSwarm}');
      }
      return llmDecision.useSwarm;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: LLM routing failed: $e, using heuristic');
      }
      return heuristicDecision.useSwarm;
    }
  }

  /// Simple heuristic routing
  SwarmRouteDecision _simpleSwarmRouting(String goal) {
    final lowerGoal = goal.toLowerCase();
    
    // Conversational patterns - DON'T use swarm
    final conversationalPatterns = [
      'hi', 'hello', 'hey', 'thanks', 'thank you', 'bye', 'goodbye',
      'how are you', 'what\'s up', 'how are you doing', 'nice to meet you',
      'good morning', 'good evening', 'good night', 'see you',
    ];
    
    // Complex task patterns - DO use swarm
    final complexTaskPatterns = [
      'analyze', 'research', 'plan', 'create a', 'design', 'develop',
      'implement', 'optimize', 'improve', 'strategy', 'recommend',
      'compare', 'evaluate', 'assess', 'review', 'audit',
      'multiple', 'several', 'various', 'comprehensive', 'detailed',
      'step by step', 'break down', 'organize', 'coordinate',
    ];
    
    // Check conversational patterns
    for (final pattern in conversationalPatterns) {
      if (lowerGoal.contains(pattern)) {
        return SwarmRouteDecision(useSwarm: false, maxSpecialists: null);
      }
    }
    
    // Count complex indicators
    int complexIndicators = 0;
    for (final pattern in complexTaskPatterns) {
      if (lowerGoal.contains(pattern)) {
        complexIndicators++;
      }
    }
    
    // Decision logic
    if (complexIndicators >= 2 || lowerGoal.length > 100) {
      return SwarmRouteDecision(
        useSwarm: true, 
        maxSpecialists: min(complexIndicators + 1, 4)
      );
    } else if (complexIndicators == 1) {
      return SwarmRouteDecision(useSwarm: true, maxSpecialists: 2);
    } else {
      return SwarmRouteDecision(useSwarm: false, maxSpecialists: null);
    }
  }

  /// Improved LLM routing decision with better error handling
  Future<SwarmRouteDecision> _llmSwarmRoutingDecision(
    BaseChatModel model,
    String goal,
  ) async {
    try {
      final system = ChatMessage.system('''
You are a routing controller. Decide if the user's request requires multi-agent swarm planning.
Return ONLY JSON: {"use_swarm": true|false, "reason": "short explanation"}
Complex tasks like analysis, planning, design, or multi-step work need swarm. Simple questions do not.
''');

      final human = ChatMessage.human(ChatMessageContent.text('USER_GOAL: $goal'));
      final response = await model.invoke(PromptValue.chat([system, human]));
      
      final text = _extractResponseText(response);
      if (text.isEmpty) {
        throw Exception('Empty response from LLM');
      }

      final decision = _parseSwarmRoutingJson(text);
      if (decision == null) {
        throw Exception('Failed to parse LLM response');
      }
      
      return decision;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: LLM routing failed: $e');
      }
      rethrow;
    }
  }

  /// Improved swarm execution with better error handling
  Future<String> _executeSwarmModeImproved(String userMessage) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Executing swarm mode for: $userMessage');
      }
      
      // Execute swarm with timeout and error handling
      final swarmResult = await _agentService.executeSwarmGoal(
        userMessage,
        conversationHistory: _messages.take(_messages.length - 1).toList(),
        maxSpecialists: 4, // Dynamic based on complexity
        timeout: Duration(minutes: 5),
      ).timeout(
        Duration(minutes: 6),
        onTimeout: () {
          throw Exception('Swarm execution timed out');
        },
      );
      
      if (swarmResult == null) {
        throw Exception('Swarm execution returned null result');
      }
      
      // Format response
      final response = _formatSwarmResponse(swarmResult);
      
      if (kDebugMode) {
        print('DEBUG: Swarm execution completed successfully');
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Swarm execution failed: $e');
      }
      
      // Return a helpful error message instead of crashing
      return '''🚫 **Swarm Mode Failed**

I attempted to use multi-agent intelligence to handle your request, but encountered an issue: ${e.toString()}

Let me try a simpler approach instead:

**Alternative Response:**
I'll help you with your request using standard AI assistance. Could you please rephrase or provide more details about what you need?

*Tip: For complex tasks, try breaking them down into smaller, specific questions.*''';
    }
  }

  /// Direct chat execution
  Future<String> _executeDirectChat(BaseChatModel model, String message) async {
    try {
      final messages = _messages.map((msg) => _convertToLangChainMessage(msg)).toList();
      final response = await model.invoke(PromptValue.chat(messages));
      
      return _extractResponseText(response);
    } catch (e) {
      throw Exception('Direct chat failed: $e');
    }
  }

  /// Extract text from LLM response
  String _extractResponseText(dynamic response) {
    try {
      if (response == null) return '';
      
      final output = response.output;
      if (output == null) return '';
      
      if (output is String) {
        return output;
      } else if (output.toString().length > 20 && 
                 !output.toString().contains('ChatMessage')) {
        return output.toString();
      }
      
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error extracting response text: $e');
      }
      return '';
    }
  }

  /// Parse swarm routing JSON
  SwarmRouteDecision? _parseSwarmRoutingJson(String text) {
    try {
      String jsonText = text.trim();
      final match = RegExp(r"\{[\s\S]*\}").firstMatch(jsonText);
      if (match != null) {
        jsonText = match.group(0)!;
      }
      
      final parsed = json.decode(jsonText) as Map<String, dynamic>?;
      if (parsed == null || !parsed.containsKey('use_swarm')) {
        return null;
      }
      
      final use = parsed['use_swarm'] == true;
      final max = parsed['max_specialists'];
      final maxInt = (max is num ? max.toInt() : null);
      
      return SwarmRouteDecision(useSwarm: use, maxSpecialists: maxInt);
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: JSON parsing failed: $e');
      }
      return null;
    }
  }

  /// Format swarm response for display
  String _formatSwarmResponse(dynamic swarmResult) {
    final buffer = StringBuffer();
    
    buffer.writeln('🤖 **Swarm Intelligence Analysis**\n');
    
    if (swarmResult.finalAnswer != null) {
      buffer.writeln(swarmResult.finalAnswer);
    } else if (swarmResult.plan != null) {
      buffer.writeln('**Execution Plan:**\n${swarmResult.plan}\n');
      
      if (swarmResult.results != null && swarmResult.results.isNotEmpty) {
        buffer.writeln('**Results:**\n');
        for (final result in swarmResult.results) {
          buffer.writeln('- $result\n');
        }
      }
    } else {
      buffer.writeln('Swarm analysis completed. Results may be limited due to execution issues.');
    }
    
    buffer.writeln('\n*This response was generated using multi-agent collaboration.*');
    
    return buffer.toString();
  }

  /// Convert ChatMessage to LangChain format
  ChatMessage _convertToLangChainMessage(ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.user:
        return ChatMessage.human(ChatMessageContent.text(message.content));
      case ChatMessageType.assistant:
        return ChatMessage.ai(ChatMessageContent.text(message.content));
      default:
        return ChatMessage.human(ChatMessageContent.text(message.content));
    }
  }

  /// Create chat model from current model configuration
  Future<BaseChatModel> _createChatModel(CurrentModel currentModel) async {
    try {
      final providers = _ref.read(enabledProvidersProvider);
      final provider = providers.firstWhere(
        (p) => p.id == currentModel.providerId,
        orElse: () => throw Exception('Provider ${currentModel.providerId} not found'),
      );
      
      return AIProviderFactory.createModel(
        provider,
        currentModel.modelId,
        currentModel.apiKey,
      );
    } catch (e) {
      throw Exception('Failed to create chat model: $e');
    }
  }

  void clearMessages() {
    _messages.clear();
    state = const ChatState.initial();
  }

  Future<void> regenerateResponse() async {
    if (_messages.length < 2) return;
    
    // Remove last assistant message and regenerate
    _messages.removeLast();
    final lastUserMessage = _messages.lastWhere((msg) => msg.type == ChatMessageType.user);
    await sendMessage(lastUserMessage.content);
  }
}

/// Chat state enum
enum ChatStateType { initial, loading, loaded, error }

/// Chat state class
class ChatState {
  final ChatStateType type;
  final List<ChatMessage> messages;
  final String? error;

  const ChatState.initial() : type = ChatStateType.initial, messages = const [], error = null;
  
  const ChatState.loading(this.messages) : type = ChatStateType.loading, error = null;
  
  const ChatState.loaded(this.messages) : type = ChatStateType.loaded, error = null;
  
  const ChatState.error(this.messages, this.error) : type = ChatStateType.error;
}

/// Provider for improved chat functionality
final improvedChatProvider = StateNotifierProvider<ImprovedChatNotifier, ChatState>((ref) {
  final agentService = ref.watch(agentServiceProvider);
  return ImprovedChatNotifier(ref, agentService);
});

/// Agent service provider
final agentServiceProvider = Provider<AgentService>((ref) {
  return AgentService();
});