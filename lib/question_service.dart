import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class Question {
  final int id;
  final String question;
  final List<String> options;
  final String answer;
  final String tag;
  final String explanation;
  final List<String> customTags;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.tag,
    required this.explanation,
    required this.customTags,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
      tag: json['tag'] ?? '',
      explanation: json['explanation'] ?? '',
      customTags: json['custom_tags'] != null ? List<String>.from(json['custom_tags']) : [],
    );
  }
}

class QuestionService {
  static Future<List<Question>> loadQuestions() async {
    final String response = await rootBundle.loadString('assets/questions.json');
    final List<dynamic> data = json.decode(response);

    List<Question> questions = data.map((q) => Question.fromJson(q)).toList();

    // Shuffle questions
    questions.shuffle(Random());

    // Shuffle options inside each question
    for (var q in questions) {
      q.options.shuffle(Random());
    }

    return questions;
  }
}
