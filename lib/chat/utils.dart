String cleanQuestionText(String raw) {
  // Hide things like "1. ..." at the start of the question text
  return raw.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '').trim();
}
