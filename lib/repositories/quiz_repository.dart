import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';

class QuizRepository {
  static final QuizRepository _instance = QuizRepository._internal();
  factory QuizRepository() => _instance;
  QuizRepository._internal();

  final List<QuestionModel> _questions = [];
  final Set<String> _seenQuestionIds = {};
  String? _activeUserId;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<QuestionModel> get allQuestions => List.unmodifiable(_questions);

  Future<void> init({String? userId}) async {
    if (_isInitialized && userId == _activeUserId) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/questions.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _questions.clear();
      for (final item in jsonList) {
        _questions.add(QuestionModel.fromJson(item as Map<String, dynamic>));
      }

      // Load any admin added/modified questions from local storage
      final prefs = await SharedPreferences.getInstance();
      final customJson = prefs.getString('custom_quiz_questions');
      if (customJson != null && customJson.isNotEmpty) {
        final List<dynamic> customList = json.decode(customJson);
        for (final item in customList) {
          final customQ = QuestionModel.fromJson(item as Map<String, dynamic>);
          final existingIdx = _questions.indexWhere((q) => q.id == customQ.id);
          if (existingIdx >= 0) {
            _questions[existingIdx] = customQ;
          } else {
            _questions.insert(0, customQ);
          }
        }
      }

      if (userId != null && userId.isNotEmpty) {
        await loadSeenQuestionsForUser(userId);
      } else {
        // Fallback seen question IDs to prevent repetition
        final seen = prefs.getStringList('seen_quiz_questions') ?? [];
        _seenQuestionIds.clear();
        _seenQuestionIds.addAll(seen);
      }

      _isInitialized = true;
    } catch (e) {
      // If error occurs, fallback gracefully
      _isInitialized = true;
    }
  }

  Future<void> loadSeenQuestionsForUser(String uid) async {
    _activeUserId = uid;
    _seenQuestionIds.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList('seen_quiz_questions_$uid') ?? [];
      _seenQuestionIds.addAll(seen);
    } catch (_) {}
  }

  void clearActiveUser() {
    _activeUserId = null;
    _seenQuestionIds.clear();
  }

  Future<void> clearSeenQuestionsForUser(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('seen_quiz_questions_$uid');
    } catch (_) {}
    if (_activeUserId == uid) {
      _seenQuestionIds.clear();
    }
  }

  List<QuestionModel> getQuestionsByCategory(String categoryId, {int? limit}) {
    final list = _questions.where((q) => q.categoryId == categoryId && q.isPublished).toList();
    if (limit != null && list.length > limit) {
      return list.take(limit).toList();
    }
    return list;
  }

  bool isCategoryExhausted(String categoryId) {
    final categoryQuestions = _questions
        .where((q) => q.categoryId == categoryId && q.isPublished)
        .toList();
    if (categoryQuestions.isEmpty) return false;
    final unseen = categoryQuestions.where((q) => !_seenQuestionIds.contains(q.id)).toList();
    return unseen.isEmpty;
  }

  void resetSeenQuestions() {
    _seenQuestionIds.clear();
    _persistSeenQuestions();
  }

  void resetCategorySeen(String categoryId) {
    final catIds = _questions
        .where((q) => q.categoryId == categoryId)
        .map((q) => q.id)
        .toSet();
    _seenQuestionIds.removeWhere((id) => catIds.contains(id));
    _persistSeenQuestions();
  }

  /// Serves questions for a round without repeating questions.
  /// Options are properly shuffled so correct answers are distributed evenly across A, B, C, D!
  List<QuestionModel> getQuestionsForRound(String categoryId, {int count = 10, int startLevel = 1}) {
    final categoryQuestions = _questions
        .where((q) => q.categoryId == categoryId && q.isPublished)
        .toList();

    if (categoryQuestions.isEmpty) return [];

    // Filter out already seen questions for this specific user to guarantee NO repetition!
    List<QuestionModel> unseen = categoryQuestions
        .where((q) => !_seenQuestionIds.contains(q.id))
        .toList();

    // If unseen questions are exhausted or fewer than requested count,
    // refresh the seen pool for this category so quizzes remain 100% UNLIMITED!
    if (unseen.length < count) {
      final catIds = categoryQuestions.map((q) => q.id).toSet();
      _seenQuestionIds.removeWhere((id) => catIds.contains(id));
      unseen = List.from(categoryQuestions);
    }

    // Shuffle questions so every round stays fresh
    unseen.shuffle();

    // Prefer questions matching or above startLevel
    final filtered = unseen.where((q) => q.difficultyLevel >= startLevel).toList();
    final List<QuestionModel> selected;
    if (filtered.length >= count) {
      selected = filtered.take(count).toList();
    } else {
      selected = unseen.take(count).toList();
    }

    // Record chosen questions as seen to prevent repetition for this user
    for (final q in selected) {
      _seenQuestionIds.add(q.id);
    }
    _persistSeenQuestions();

    // Ensure every question has its options shuffled and correctOptionIndex mapped dynamically
    return selected.map((q) => q.withShuffledOptions()).toList();
  }

  Future<void> _persistSeenQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeUserId != null && _activeUserId!.isNotEmpty) {
        await prefs.setStringList('seen_quiz_questions_$_activeUserId', _seenQuestionIds.toList());
      } else {
        await prefs.setStringList('seen_quiz_questions', _seenQuestionIds.toList());
      }
    } catch (_) {}
  }

  Future<void> saveQuestion(QuestionModel question) async {
    final index = _questions.indexWhere((q) => q.id == question.id);
    if (index >= 0) {
      _questions[index] = question;
    } else {
      _questions.insert(0, question);
    }
    await _persistCustomQuestions();
  }

  Future<void> deleteQuestion(String questionId) async {
    _questions.removeWhere((q) => q.id == questionId);
    await _persistCustomQuestions();
  }

  Future<void> togglePublish(String questionId) async {
    final index = _questions.indexWhere((q) => q.id == questionId);
    if (index >= 0) {
      final current = _questions[index];
      _questions[index] = current.copyWith(isPublished: !current.isPublished);
      await _persistCustomQuestions();
    }
  }

  Future<void> _persistCustomQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final customList = _questions.map((q) => q.toJson()).toList();
    await prefs.setString('custom_quiz_questions', json.encode(customList));
  }
}
