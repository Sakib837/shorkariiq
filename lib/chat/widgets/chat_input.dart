import 'package:flutter/material.dart';
import '../chat_theme.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String text) onSubmit;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  onSubmit(val.trim());
                  controller.clear();
                }
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a message, 'quiz' or 'review'...",
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: ChatTheme.userBubble.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onSubmit(val);
                controller.clear();
              }
            },
          )
        ],
      ),
    );
  }
}
