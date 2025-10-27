import 'package:langchain/langchain.dart';
import 'package:micro/features/chat/data/sources/llm_data_source.dart';
import 'package:micro/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final LlmDataSource _llmDataSource;

  ChatRepositoryImpl(this._llmDataSource);

  @override
  Future<ChatMessage> sendMessage(String message) {
    return _llmDataSource.sendMessage(message);
  }
}
