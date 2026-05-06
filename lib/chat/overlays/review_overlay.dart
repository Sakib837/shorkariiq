import 'package:flutter/material.dart';
import '../../question_service.dart';
import '../utils.dart';

class ReviewOverlay extends StatelessWidget {
  final bool finished;
  final List<Question> questions;
  final int currentIndex;
  final Map<int, String> answers;
  final int score;

  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSubmitPressed;
  final void Function(String answer) onSelect;
  final VoidCallback onBackToChat;
  final VoidCallback onReviewAgain;

  final Map<int, String> explanations;
  final Set<int> loadingExplanations;
  final void Function(int idx) onExplain;

  const ReviewOverlay({
    super.key,
    required this.finished,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.score,
    required this.onPrev,
    required this.onNext,
    required this.onSubmitPressed,
    required this.onSelect,
    required this.onBackToChat,
    required this.onReviewAgain,
    required this.explanations,
    required this.loadingExplanations,
    required this.onExplain,
  });

  @override
  Widget build(BuildContext context) {
    if (finished) return _buildSummary(context);

    final q = questions[currentIndex];
    final total = questions.length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (currentIndex + 1) / total,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Review ${currentIndex + 1} of $total",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              cleanQuestionText(q.question),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...q.options.map((opt) {
            final isSelected = answers[currentIndex] == opt;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.blue : Colors.grey.shade900,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => onSelect(opt),
                child: Text(opt, style: const TextStyle(fontSize: 17)),
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (currentIndex > 0)
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  label: const Text("Previous", style: TextStyle(color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue, width: 1.5),
                  ),
                  onPressed: onPrev,
                ),
              const SizedBox(width: 24),
              if (currentIndex < total - 1)
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                  label: const Text("Next", style: TextStyle(color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue, width: 1.5),
                  ),
                  onPressed: onNext,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Submit Review"),
            onPressed: onSubmitPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final total = questions.length;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Review Finished!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
          const SizedBox(height: 8),
          Text("You scored $score out of $total",
              style: const TextStyle(fontSize: 18, color: Colors.black)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Back to Chat"),
            onPressed: onBackToChat,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text("Review Again"),
            onPressed: onReviewAgain,
          ),
          const SizedBox(height: 30),
          Text("Reviewed Q/A:",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, idx) {
                final q = questions[idx];
                final userAns = answers[idx];
                final correct = userAns == q.answer;

                return Card(
                  color: correct ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cleanQuestionText(q.question),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                        const SizedBox(height: 4),
                        Text("Your answer: ${userAns ?? "No answer"}",
                            style: TextStyle(color: correct ? Colors.green : Colors.red)),
                        Text("Correct answer: ${q.answer}", style: const TextStyle(color: Colors.green)),
                        const SizedBox(height: 6),
                        if (explanations.containsKey(idx))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(explanations[idx]!, style: const TextStyle(color: Colors.black87)),
                          )
                        else if (loadingExplanations.contains(idx))
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text("Getting explanation...", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            icon: const Icon(Icons.lightbulb_outline),
                            label: const Text("Explain"),
                            onPressed: () => onExplain(idx),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
