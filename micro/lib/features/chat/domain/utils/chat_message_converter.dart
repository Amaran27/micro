import 'package:langchain_core/src/chat_models/types.dart' as langchain_core;
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/domain/models/chat/chat_message.dart' show MessageType;

micro.ChatMessage convertLangchainChatMessage(
    langchain_core.ChatMessage langchainMessage) {
  String content = '';
  MessageType messageType = MessageType.system; // Default to system

  if (langchainMessage is langchain_core.HumanChatMessage) {
    messageType = MessageType.user;
    if (langchainMessage.content is String) {
      content = langchainMessage.content as String;
    } else {
      content = langchainMessage.content.toString(); // Fallback to toString()
    }
  } else if (langchainMessage is langchain_core.AIChatMessage) {
    messageType = MessageType.assistant;
    content = langchainMessage.content;
  } else if (langchainMessage is langchain_core.SystemChatMessage) {
    messageType = MessageType.system;
    content = langchainMessage.content;
  } else {
    content = langchainMessage.toString(); // Fallback for unknown types
  }

  return micro.ChatMessage(
    id: DateTime.now().toIso8601String(), // Generate a unique ID
    timestamp: DateTime.now(),
    type: messageType,
    content: content,
  );
}
