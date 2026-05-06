enum Sender { user, bot, system }

class ChatMessage {
  final String text;
  final Sender sender;
  const ChatMessage({required this.text, required this.sender});
}
