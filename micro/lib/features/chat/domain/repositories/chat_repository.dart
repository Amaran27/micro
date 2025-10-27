import 'package:langchain/langchain.dart';

abstract class ChatRepository {
  Future<ChatMessage> sendMessage(String message);
}
