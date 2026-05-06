import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class UserProgress {
  String username;
  String? password;
  List<dynamic> quizzes;
  Map<String, int> failedTags;
  List<dynamic> spacedReview;
  int? reminderDays;
  String language; // NEW: 'en' or 'bn'

  UserProgress({
    required this.username,
    this.password,
    List<dynamic>? quizzes,
    Map<String, int>? failedTags,
    List<dynamic>? spacedReview,
    this.reminderDays,
    String? language,
  })  : quizzes = quizzes ?? [],
        failedTags = failedTags ?? {},
        spacedReview = spacedReview ?? [],
        language = language ?? 'en'; // default English

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      username: json['username'],
      password: json['password'],
      quizzes: json['quizzes'] ?? [],
      failedTags: Map<String, int>.from(json['failedTags'] ?? {}),
      spacedReview: json['spacedReview'] ?? [],
      reminderDays: json['reminderDays'],
      language: (json['language'] as String?) ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'quizzes': quizzes,
    'failedTags': failedTags,
    'spacedReview': spacedReview,
    'reminderDays': reminderDays,
    'language': language,
  };
}

class UserService {
  static const String assetPath = 'assets/user_progress.json';
  static String? _localPath;
  static List<UserProgress> _users = [];
  static UserProgress? currentUser;

  static Future<String> get localPath async {
    if (_localPath != null) return _localPath!;
    final directory = await getApplicationDocumentsDirectory();
    _localPath = '${directory.path}/user_progress.json';
    return _localPath!;
  }

  static Future<void> ensureLocalFileExists() async {
    final path = await localPath;
    final file = File(path);
    if (!await file.exists()) {
      final assetData = await rootBundle.loadString(assetPath);
      await file.writeAsString(assetData);
    }
  }

  static Future<void> loadUsers() async {
    await ensureLocalFileExists();
    final file = File(await localPath);
    final jsonStr = await file.readAsString();
    List list = [];
    try {
      list = json.decode(jsonStr);
    } catch (_) {
      list = [];
    }
    _users = list.map((u) => UserProgress.fromJson(u)).toList();
  }

  static Future<void> saveUsers() async {
    final file = File(await localPath);
    final str = json.encode(_users.map((u) => u.toJson()).toList());
    await file.writeAsString(str);
  }

  static Future<UserProgress?> login(String username, String? password) async {
    await loadUsers();
    for (var u in _users) {
      if (u.username == username && (u.password == password || u.password == null)) {
        currentUser = u;
        return u;
      }
    }
    return null;
  }

  static Future<UserProgress> signup(String username, String? password) async {
    await loadUsers();
    if (_users.any((u) => u.username == username)) {
      throw Exception('Username already exists');
    }
    final u = UserProgress(username: username, password: password);
    _users.add(u);
    currentUser = u;
    await saveUsers();
    return u;
  }
}
