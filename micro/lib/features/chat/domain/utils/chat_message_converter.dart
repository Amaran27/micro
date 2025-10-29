import 'package:langchain_core/src/chat_models/types.dart' as langchain_core;
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/domain/models/chat/chat_message.dart' show MessageType;

micro.ChatMessage convertLangchainChatMessage(
    langchain_core.ChatMessage langchainMessage) {
  String content = '';
  MessageType messageType = MessageType.system; // Default to system

  if (langchainMessage is langchain_core.HumanChatMessage) {
    messageType = MessageType.user;
    // Extract text from ChatMessageContent
    final contentObj = langchainMessage.content;
    if (contentObj is langchain_core.ChatMessageContentText) {
      content = contentObj.text;
    } else {
      // Try to extract text from the content object
      try {
        content = contentObj.toString();
        // If it's JSON-like, try to extract the text field
        if (content.contains('"text":')) {
          final textMatch = RegExp(r'"text":\s*"([^"]*)"').firstMatch(content);
          if (textMatch != null) {
            content = textMatch.group(1) ?? content;
          }
        }
      } catch (e) {
        content = 'Unable to extract message content';
      }
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
