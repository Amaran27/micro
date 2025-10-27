import 'package:langchain/langchain.dart';
import 'package:micro/features/chat/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _chatRepository;

  SendMessageUseCase(this._chatRepository);

  Future<ChatMessage> call(String message) {
    return _chatRepository.sendMessage(message);
  }
}
