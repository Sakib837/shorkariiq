import 'package:flutter/material.dart';
import '../models.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  const MessageList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, idx) {
        final msg = messages[messages.length - 1 - idx];
        return MessageBubble(message: msg);
    });
  }
}
