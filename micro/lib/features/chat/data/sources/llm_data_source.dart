import 'package:langchain/langchain.dart';
import 'package:micro/infrastructure/ai/ai_provider_config.dart';

class LlmDataSource {
  final AIProviderConfig _aiProviderConfig;

  LlmDataSource(this._aiProviderConfig);

  Future<ChatMessage> sendMessage(String message) async {
    final chatModel = _aiProviderConfig.getBestAvailableChatModel();
    if (chatModel == null) {
      throw Exception('No AI chat model available.');
    }

    final humanMessage = ChatMessage.human(ChatMessageContent.text(message));
    final response = await chatModel.call([humanMessage]);
    return response;
  }
}
