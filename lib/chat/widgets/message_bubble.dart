import 'package:flutter/material.dart';
import '../chat_theme.dart';
import '../models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final align = message.sender == Sender.user
        ? Alignment.centerRight
        : message.sender == Sender.bot
            ? Alignment.centerLeft
            : Alignment.center;

    final color = message.sender == Sender.user
        ? ChatTheme.userBubble
        : message.sender == Sender.bot
            ? ChatTheme.botBubble
            : ChatTheme.systemBubble;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text, style: ChatTheme.chatText),
      ),
    );
  }
}
