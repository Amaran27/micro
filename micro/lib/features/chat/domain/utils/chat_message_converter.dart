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
    content = _extractTextContent(contentObj);
  } else if (langchainMessage is langchain_core.AIChatMessage) {
    messageType = MessageType.assistant;
    final contentObj = langchainMessage.content;
    content = _extractTextContent(contentObj);
  } else if (langchainMessage is langchain_core.SystemChatMessage) {
    messageType = MessageType.system;
    final contentObj = langchainMessage.content;
    content = _extractTextContent(contentObj);
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

/// Extract text content from ChatMessageContent
String _extractTextContent(dynamic contentObj) {
  if (contentObj is String) {
    return contentObj;
  } else if (contentObj is langchain_core.ChatMessageContentText) {
    return contentObj.text;
  } else if (contentObj is langchain_core.ChatMessageContent) {
    // ChatMessageContent doesn't expose parts directly, convert to string
    return contentObj.toString();
  } else {
    // Try to extract text from the content object
    try {
      final str = contentObj.toString();
      // If it's JSON-like, try to extract the text field
      if (str.contains('"text":')) {
        final textMatch = RegExp(r'"text":\s*"([^"]*)"').firstMatch(str);
        if (textMatch != null) {
          return textMatch.group(1) ?? str;
        }
      }
      return str;
    } catch (e) {
      return 'Unable to extract message content';
    }
  }
}
