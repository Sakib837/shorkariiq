// lib/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'chat/chat_theme.dart';
import 'chat/models.dart';
import 'chat/widgets/message_list.dart';
import 'chat/widgets/chat_input.dart';
import 'chat/overlays/quiz_overlay.dart';
import 'chat/overlays/review_overlay.dart';
import 'chat/sheets/user_menu_sheet.dart';
import 'chat/dialogs/review_reminder_dialog.dart';
import 'chat/dialogs/language_dialog.dart';

import 'question_service.dart';
import 'gemini_service.dart';
import 'user_service.dart';
import 'notification_service.dart';
import 'progress_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ChatScreen({super.key, required this.onLogout});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Chat messages
  final List<ChatMessage> messages = [];
  final TextEditingController inputController = TextEditingController();

  // Quiz State
  bool quizMode = false;
  List<Question> quizQuestions = [];
  Map<int, String> selectedAnswers = {};
  int currentQuestion = 0;
  int score = 0;
  Timer? quizTimer;
  int quizSecondsLeft = 360; // 6 minutes
  bool quizFinished = false;

  // Explanations (used by quiz & review summaries)
  Map<int, String> explanations = {};
  Set<int> loadingExplanations = {};

  // Review State
  bool reviewMode = false;
  List<Map<String, dynamic>> dueReviews = [];
  List<Question> reviewQuestions = [];
  Map<int, String> reviewAnswers = {};
  int reviewIndex = 0;
  int reviewScore = 0;
  bool reviewFinished = false;

  // Language helpers
  String get _langCode => UserService.currentUser?.language ?? 'en';
  String _t(String en, String bn) => _langCode == 'bn' ? bn : en;

  @override
  void initState() {
    super.initState();
    // Language-specific greeting when entering chat
    messages.add(ChatMessage(
      text: _t(
        "Hi! Type 'quiz' to start a quiz or 'review' to practice your mistakes.",
        "হাই! কুইজ শুরু করতে 'quiz' লিখুন বা ভুলগুলো অনুশীলন করতে 'review' লিখুন।",
      ),
      sender: Sender.bot,
    ));
    _checkDueReviews();
  }

  // ---------------- Chat Logic ----------------
  Future<void> handleUserInput(String text) async {
    final lower = text.trim().toLowerCase();
    _addMessage(text, Sender.user);

    if (!quizMode && !reviewMode && lower.contains('review')) {
      await _startReviewMode();
      return;
    }
    if (!quizMode && (lower.contains('quiz') || lower.contains('test'))) {
      await _startQuiz();
      return;
    }

    _addMessage(_t("Let me think...", "একটু ভাবছি..."), Sender.bot);
    final geminiResponse = await GeminiService.chatWithGemini(
      text,
      targetLang: _langCode, // language applied to chat responses
    );
    _addMessage(geminiResponse, Sender.bot);
  }

  void _addMessage(String text, Sender sender) {
    setState(() => messages.add(ChatMessage(text: text, sender: sender)));
  }

  // ---------------- Quiz Logic ----------------
  Future<void> _startQuiz() async {
    setState(() {
      quizMode = true;
      quizFinished = false;
      reviewMode = false;
      reviewFinished = false;
      currentQuestion = 0;
      score = 0;
      selectedAnswers = {};
      explanations = {};
      loadingExplanations = {};
    });
    final allQuestions = await QuestionService.loadQuestions();
    allQuestions.shuffle();
    setState(() {
      quizQuestions = allQuestions.take(10).toList();
      quizSecondsLeft = 360;
    });
    _startQuizTimer();
    _addMessage(
      _t(
        "Quiz started! You have 6 minutes for 10 questions. Good luck!",
        "কুইজ শুরু হয়েছে! ১০টি প্রশ্নের জন্য আপনার কাছে ৬ মিনিট সময় আছে। শুভকামনা!",
      ),
      Sender.system,
    );
  }

  void _startQuizTimer() {
    quizTimer?.cancel();
    quizTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (quizSecondsLeft > 0) {
          quizSecondsLeft--;
        } else {
          _finishQuiz();
        }
      });
    });
  }

  void _selectAnswer(String answer) =>
      setState(() => selectedAnswers[currentQuestion] = answer);

  void _nextQuizQuestion() {
    if (currentQuestion < quizQuestions.length - 1) {
      setState(() => currentQuestion++);
    }
  }

  void _prevQuizQuestion() {
    if (currentQuestion > 0) {
      setState(() => currentQuestion--);
    }
  }

  void _submitQuizPressed() {
    if (selectedAnswers.length == quizQuestions.length || quizSecondsLeft <= 0) {
      _finishQuiz();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(_t("Submit Quiz?", "কুইজ সাবমিট করবেন?")),
          content: Text(
            _t(
              "You have answered ${selectedAnswers.length} of ${quizQuestions.length} questions.\nSubmit anyway?",
              "আপনি ${quizQuestions.length}টির মধ্যে ${selectedAnswers.length}টি প্রশ্নের উত্তর দিয়েছেন।\nতবুও সাবমিট করবেন?",
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_t("Cancel", "বাতিল"))),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _finishQuiz();
              },
              child: Text(_t("Submit", "সাবমিট")),
            ),
          ],
        ),
      );
    }
  }

  void _finishQuiz() {
    quizTimer?.cancel();
    int correct = 0;
    final List<Map<String, dynamic>> questionDetails = [];
    final user = UserService.currentUser;
    final now = DateTime.now().toUtc();
    Map<String, int> failedTags = user?.failedTags ?? {};
    List<Map<String, dynamic>> spacedReviewList =
    user != null ? List<Map<String, dynamic>>.from(user.spacedReview) : [];

    for (int i = 0; i < quizQuestions.length; i++) {
      final q = quizQuestions[i];
      final userAns = selectedAnswers[i];
      final isCorrect = userAns == q.answer;

      if (!isCorrect) {
        for (final tag in q.customTags) {
          failedTags[tag] = (failedTags[tag] ?? 0) + 1;
        }
        // Add/update in spacedReview; mark due NOW so a follow-up review shows them immediately
        final existingIndex =
        spacedReviewList.indexWhere((r) => r['questionId'] == q.id);
        if (existingIndex >= 0) {
          spacedReviewList[existingIndex]['interval'] = 1;
          spacedReviewList[existingIndex]['nextReview'] = now.toIso8601String();
        } else {
          spacedReviewList.add({
            'questionId': q.id,
            'interval': 1,
            'nextReview': now.toIso8601String(),
            'tags': q.customTags,
          });
        }
      }
      questionDetails.add({
        'id': q.id, // kept for mapping only; never displayed
        'userAnswer': userAns,
        'correct': isCorrect,
        'tags': q.customTags,
      });
      if (isCorrect) correct++;
    }

    setState(() {
      score = correct;
      quizFinished = true;
      quizMode = false;
    });

    if (user != null) {
      user.quizzes.add({
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'score': score,
        'questions': questionDetails,
      });
      user.failedTags = failedTags;
      user.spacedReview = spacedReviewList;
      UserService.saveUsers();
    }

    _addMessage(
      _t(
        "Quiz finished! You scored $score out of ${quizQuestions.length}.",
        "কুইজ শেষ! আপনি স্কোর করেছেন ${quizQuestions.length} এর মধ্যে $score।",
      ),
      Sender.system,
    );
    _addMessage(
      _t(
        "Type 'review' to practice mistakes, or 'quiz' to try another.",
        "ভুলগুলো অনুশীলন করতে 'review' লিখুন, অথবা আরেকটি কুইজ করতে 'quiz' লিখুন।",
      ),
      Sender.bot,
    );
    _checkDueReviews();
  }

  Future<void> _explainQuiz(int idx) async {
    setState(() => loadingExplanations.add(idx));
    final q = quizQuestions[idx];
    final userAns = selectedAnswers[idx];
    final prompt =
        "Explain why the answer to this question is '${q.answer}'.\n"
        "Question: ${q.question}\n"
        "Options: ${q.options.join(', ')}\n"
        "User's answer: ${userAns ?? 'None'}";
    final geminiResponse = await GeminiService.chatWithGemini(
      prompt,
      targetLang: _langCode, // language applied to explanations
    );
    setState(() {
      explanations[idx] = geminiResponse;
      loadingExplanations.remove(idx);
    });
  }

  // ---------------- Review Logic ----------------

  void _checkDueReviews() {
    final user = UserService.currentUser;
    if (user == null) return;
    final now = DateTime.now().toUtc();
    final due = user.spacedReview.where((r) {
      final nextReview = DateTime.tryParse(r['nextReview'] ?? '');
      return nextReview != null && !nextReview.isAfter(now);
    }).toList();
    if (due.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _addMessage(
          _t(
            "You have ${due.length} review question(s) due! Type 'review' to start Review Mode.",
            "আপনার ${due.length}টি রিভিউ প্রশ্ন বাকি আছে! রিভিউ শুরু করতে 'review' লিখুন।",
          ),
          Sender.system,
        );
      });
    }
  }

  /// Helper for (re)opening review mode; optionally shows a dialog when no items are due.
  Future<bool> _openReviewMode({bool showDialogIfEmpty = false}) async {
    final user = UserService.currentUser;
    if (user == null) return false;
    final now = DateTime.now().toUtc();

    // Collect due items
    List<Map<String, dynamic>> due = user.spacedReview
        .where((r) {
      final nextReview = DateTime.tryParse(r['nextReview'] ?? '');
      return nextReview != null && !nextReview.isAfter(now);
    })
        .map((r) => r as Map<String, dynamic>)
        .toList();

    // Randomize and cap to 10
    due.shuffle();
    if (due.length > 10) due = due.sublist(0, 10);

    if (due.isEmpty) {
      if (showDialogIfEmpty && mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(_t("Nothing to review", "রিভিউ করার কিছু নেই")),
            content: Text(_t(
              "Great job! You have no review questions due right now.",
              "দারুণ! এখন রিভিউ করার মতো কোনো প্রশ্ন নেই।",
            )),
          ),
        );
      } else {
        _addMessage(
          _t(
            "No review questions due right now. Keep learning!",
            "এখন রিভিউ করার মতো কোনো প্রশ্ন নেই। শেখা চালিয়ে যান!",
          ),
          Sender.system,
        );
      }
      return false;
    }

    // Load Questions from IDs
    final allQuestions = await QuestionService.loadQuestions();
    final List<Question> qs = [];
    for (final r in due) {
      final match = allQuestions.where((qq) => qq.id == r['questionId']);
      if (match.isNotEmpty) qs.add(match.first);
    }
    if (qs.isEmpty) {
      if (showDialogIfEmpty && mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(_t("Nothing to review", "রিভিউ করার কিছু নেই")),
            content: Text(_t(
              "No matching questions found for your review items.",
              "আপনার রিভিউ আইটেমগুলোর জন্য মিলযুক্ত প্রশ্ন পাওয়া যায়নি।",
            )),
          ),
        );
      } else {
        _addMessage(
          _t(
            "No review questions due right now. Keep learning!",
            "এখন রিভিউ করার মতো কোনো প্রশ্ন নেই। শেখা চালিয়ে যান!",
          ),
          Sender.system,
        );
      }
      return false;
    }

    setState(() {
      dueReviews = due;
      reviewQuestions = qs;
      reviewMode = true;
      reviewFinished = false;
      reviewIndex = 0;
      reviewScore = 0;
      reviewAnswers = {};
      explanations = {};
      loadingExplanations = {};
    });

    _addMessage(
      _t(
        "Review Mode started! Let's reinforce what you missed.",
        "রিভিউ শুরু হলো! চলুন মিস করা বিষয়গুলো শক্ত করি।",
      ),
      Sender.system,
    );
    return true;
  }

  /// Entry point when user types 'review' in chat (keeps system message behavior)
  Future<void> _startReviewMode() async {
    await _openReviewMode(showDialogIfEmpty: false);
  }

  void _selectReviewAnswer(String answer) =>
      setState(() => reviewAnswers[reviewIndex] = answer);

  void _nextReviewQuestion() {
    if (reviewIndex < reviewQuestions.length - 1) {
      setState(() => reviewIndex++);
    }
  }

  void _prevReviewQuestion() {
    if (reviewIndex > 0) {
      setState(() => reviewIndex--);
    }
  }

  void _submitReviewPressed() {
    final total = reviewQuestions.length;
    if (reviewAnswers.length == total) {
      _finishReview();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(_t("Submit Review?", "রিভিউ সাবমিট করবেন?")),
          content: Text(
            _t(
              "You have answered ${reviewAnswers.length} of $total questions.\nSubmit anyway?",
              "আপনি $totalটির মধ্যে ${reviewAnswers.length}টির উত্তর দিয়েছেন।\nতবুও সাবমিট করবেন?",
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(_t("Cancel", "বাতিল"))),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _finishReview();
              },
              child: Text(_t("Submit", "সাবমিট")),
            ),
          ],
        ),
      );
    }
  }

  void _finishReview() {
    int correct = 0;
    final user = UserService.currentUser;
    final now = DateTime.now().toUtc();

    if (user != null) {
      for (int i = 0; i < reviewQuestions.length; i++) {
        final q = reviewQuestions[i];
        final userAns = reviewAnswers[i];
        final isCorrect = userAns == q.answer;
        if (isCorrect) correct++;

        final idx = user.spacedReview.indexWhere((r) => r['questionId'] == q.id);

        if (isCorrect) {
          // Remove corrected items
          if (idx >= 0) {
            user.spacedReview.removeAt(idx);
          }
        } else {
          // Keep wrong items and make them due NOW (so Review Again shows them immediately)
          if (idx >= 0) {
            user.spacedReview[idx]['interval'] = 1;
            user.spacedReview[idx]['nextReview'] = now.toIso8601String();
          } else {
            user.spacedReview.add({
              'questionId': q.id,
              'interval': 1,
              'nextReview': now.toIso8601String(),
              'tags': q.customTags,
            });
          }
        }
      }
      UserService.saveUsers();
    }

    setState(() {
      reviewScore = correct;
      reviewFinished = true;
      reviewMode = false;
    });

    _addMessage(
      _t(
        "Review finished! You scored $reviewScore out of ${reviewQuestions.length}.",
        "রিভিউ শেষ! আপনি স্কোর করেছেন ${reviewQuestions.length} এর মধ্যে $reviewScore।",
      ),
      Sender.system,
    );
    _checkDueReviews();
  }

  Future<void> _explainReview(int idx) async {
    setState(() => loadingExplanations.add(idx));
    final q = reviewQuestions[idx];
    final userAns = reviewAnswers[idx];
    final prompt =
        "Explain why the answer to this question is '${q.answer}'.\n"
        "Question: ${q.question}\n"
        "Options: ${q.options.join(', ')}\n"
        "User's answer: ${userAns ?? 'None'}";
    final geminiResponse = await GeminiService.chatWithGemini(
      prompt,
      targetLang: _langCode, // language applied to explanations
    );
    setState(() {
      explanations[idx] = geminiResponse;
      loadingExplanations.remove(idx);
    });
  }

  // ---------------- User Menu / Reminders / Language ----------------
  Future<void> _openUserMenu() async {
    final user = UserService.currentUser;
    await showUserMenuSheet(
      context,
      username: user?.username,
      languageLabel: _langCode == 'bn' ? 'বাংলা' : 'English',
      onSetReminder: () async {
        final user = UserService.currentUser;
        final days = await showReviewReminderDialog(
          context,
          // Before: initialDays: user?.reminderDays ?? 1,
          initialDays: user?.reminderDays, // <-- pass through as-is (null means Off)
        );
        if (days != null) {
          if (days <= 0) {
            if (user != null) {
              user.reminderDays = null;           // <-- store OFF as null
              await UserService.saveUsers();
            }
            await NotificationService.cancelReviewReminder();
            _addMessage(
              _t("Review reminders turned OFF.", "রিভিউ রিমাইন্ডার বন্ধ করা হয়েছে।"),
              Sender.system,
            );
          } else {
            if (user != null) {
              user.reminderDays = days;
              await UserService.saveUsers();
            }
            await NotificationService.scheduleReviewReminderPeriodDays(days);
            _addMessage(
              _t(
                "Review reminder set for every $days day(s).",
                "রিভিউ রিমাইন্ডার সেট হয়েছে প্রতি $days দিন পর।",
              ),
              Sender.system,
            );
          }
        }
      },
      onChangeLanguage: () async {
        final selected = await showLanguageDialog(context, initial: _langCode);
        if (selected != null && user != null) {
          user.language = selected;
          await UserService.saveUsers();
          final msg = selected == 'bn'
              ? "ভাষা বাংলা করা হয়েছে। এখন থেকে চ্যাট ও ব্যাখ্যা বাংলায় দেখানো হবে।"
              : "Language changed to English. Chat and explanations will appear in English.";
          _addMessage(msg, Sender.system);
          setState(() {}); // refresh any UI labels
        }
      },
      onViewProgress: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProgressDetailsScreen()),
        );
      },
      onLogout: () {
        UserService.currentUser = null;
        widget.onLogout();
      },
    );
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ShorkariIQ"),
        backgroundColor: ChatTheme.darkBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'User / Menu',
            onPressed: _openUserMenu,
          ),
        ],
      ),
      backgroundColor: ChatTheme.darkBlue,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: MessageList(messages: messages)),
              if (!quizMode && !reviewMode)
                ChatInput(controller: inputController, onSubmit: handleUserInput),
            ],
          ),

          // Quiz Overlay
          if (quizMode || quizFinished)
            Positioned.fill(
              child: Material(
                color: Colors.white.withOpacity(0.98),
                child: QuizOverlay(
                  finished: quizFinished,
                  questions: quizQuestions,
                  currentIndex: currentQuestion,
                  selectedAnswers: selectedAnswers,
                  secondsLeft: quizSecondsLeft,
                  score: score,
                  onPrev: _prevQuizQuestion,
                  onNext: _nextQuizQuestion,
                  onSubmitPressed: _submitQuizPressed,
                  onSelect: _selectAnswer,
                  onBackToChat: () {
                    setState(() {
                      quizFinished = false;
                      explanations = {};
                      loadingExplanations = {};
                    });
                    _checkDueReviews();
                  },
                  onTryAgain: _startQuiz,
                  explanations: explanations,
                  loadingExplanations: loadingExplanations,
                  onExplain: _explainQuiz,
                ),
              ),
            ),

          // Review Overlay
          if (reviewMode || reviewFinished)
            Positioned.fill(
              child: Material(
                color: Colors.white.withOpacity(0.98),
                child: ReviewOverlay(
                  finished: reviewFinished,
                  questions: reviewQuestions,
                  currentIndex: reviewIndex,
                  answers: reviewAnswers,
                  score: reviewScore,
                  onPrev: _prevReviewQuestion,
                  onNext: _nextReviewQuestion,
                  onSubmitPressed: _submitReviewPressed,
                  onSelect: _selectReviewAnswer,
                  onBackToChat: () {
                    setState(() {
                      reviewFinished = false;
                      reviewAnswers = {};
                    });
                    _checkDueReviews();
                  },
                  // If nothing due, show a dialog (not just a system message)
                  onReviewAgain: () => _openReviewMode(showDialogIfEmpty: true),
                  explanations: explanations,
                  loadingExplanations: loadingExplanations,
                  onExplain: _explainReview,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    quizTimer?.cancel();
    inputController.dispose();
    super.dispose();
  }
}
