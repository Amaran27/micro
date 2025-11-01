import 'package:langchain/langchain.dart';
import 'package:micro/infrastructure/ai/ai_provider_config.dart';

class LlmDataSource {
  final AIProviderConfig _aiProviderConfig;

  LlmDataSource(this._aiProviderConfig);

  Future<ChatMessage> sendMessage(String message) async {
    final adapter = _aiProviderConfig.getBestAvailableChatModel();
    if (adapter == null || !adapter.isInitialized) {
      throw Exception('No AI provider available.');
    }

    // Use the adapter's sendMessage method
    final response = await adapter.sendMessage(
      text: message,
      history: [], // No history for simple LLM data source
    );
    
    // Convert back to langchain format if needed
    return ChatMessage.ai(response.content);
  }
}
