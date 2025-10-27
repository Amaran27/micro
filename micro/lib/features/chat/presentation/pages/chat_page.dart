import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/domain/models/chat/chat_message.dart';
import 'package:micro/features/chat/presentation/providers/chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message =
                    chatState.messages[chatState.messages.length - 1 - index];
                return Align(
                  alignment: message.type == MessageType.user
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: message.type == MessageType.user
                          ? Colors.blue[100]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(message.content),
                  ),
                );
              },
            ),
          ),
          if (chatState.isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (chatState.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${chatState.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Send a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      chatNotifier.sendMessage(text);
                      _controller.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: chatState.isLoading
                      ? null
                      : () {
                          chatNotifier.sendMessage(_controller.text);
                          _controller.clear();
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
