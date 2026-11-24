import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../repositories/quiz_repository.dart';
import '../core/audio/audio_manager.dart';
import '../services/wallet_service.dart';

class QuizProvider with ChangeNotifier {
  final QuizRepository _quizRepo = QuizRepository();
  final AudioManager _audio = AudioManager();
  final WalletService _walletService = WalletService();

  CategoryModel? _currentCategory;
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  int _pointsEarned = 0;

  int _remainingSeconds = 30;
  Timer? _timer;

  int _selectedOption = -1;
  bool _isAnswerChecked = false;
  bool _isQuizCompleted = false;

  // Active hints state for current question
  final Set<int> _eliminatedOptions = {};
  bool _isClueRevealed = false;
  bool _isHintUsed = false;

  // Getters
  CategoryModel? get currentCategory => _currentCategory;
  List<QuestionModel> get questions => _questions;
  int get currentIndex => _currentIndex;
  QuestionModel? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length ? _questions[_currentIndex] : null;
  int get score => _score;
  int get correctCount => _correctCount;
  int get incorrectCount => _incorrectCount;
  int get pointsEarned => _pointsEarned;
  int get remainingSeconds => _remainingSeconds;
  int get selectedOption => _selectedOption;
  bool get isAnswerChecked => _isAnswerChecked;
  bool get isQuizCompleted => _isQuizCompleted;
  Set<int> get eliminatedOptions => _eliminatedOptions;
  bool get isClueRevealed => _isClueRevealed;
  bool get isHintUsed => _isHintUsed;

  void startQuizRound(CategoryModel category, {int startLevel = 1, int count = 10}) {
    _currentCategory = category;
    _questions = _quizRepo.getQuestionsForRound(category.id, count: count, startLevel: startLevel);
    _currentIndex = 0;
    _score = 0;
    _correctCount = 0;
    _incorrectCount = 0;
    _pointsEarned = 0;
    _isQuizCompleted = false;

    _resetQuestionState();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    if (currentQuestion == null) return;
    _remainingSeconds = currentQuestion!.timerDuration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0 && !_isAnswerChecked) {
        _remainingSeconds--;
        if (_remainingSeconds <= 5 && _remainingSeconds > 0) {
          _audio.playTick();
        }
        notifyListeners();
      } else if (_remainingSeconds <= 0 && !_isAnswerChecked) {
        // Time expired! Mark wrong automatically
        _timer?.cancel();
        selectOption(-1); // timeout
      }
    });
  }

  void selectOption(int index) {
    if (_isAnswerChecked || currentQuestion == null) return;

    _timer?.cancel();
    _selectedOption = index;
    _isAnswerChecked = true;

    final isCorrect = (index == currentQuestion!.correctOptionIndex);

    if (isCorrect) {
      _correctCount++;
      _score += 10;
      final pts = currentQuestion!.pointsReward;
      _pointsEarned += pts;
      _audio.playCorrect();
    } else {
      _incorrectCount++;
      _audio.playWrong();
    }

    notifyListeners();
  }

  // Hints
  void apply5050Hint() {
    if (currentQuestion == null || _eliminatedOptions.isNotEmpty) return;
    _isHintUsed = true;
    final correctIdx = currentQuestion!.correctOptionIndex;
    final incorrectIndices = [0, 1, 2, 3]..remove(correctIdx);
    incorrectIndices.shuffle();

    // Eliminate two incorrect options
    _eliminatedOptions.addAll(incorrectIndices.take(2));
    _audio.playClick();
    notifyListeners();
  }

  void applyExtraTimeHint() {
    _isHintUsed = true;
    _remainingSeconds += 15;
    _audio.playCoin();
    notifyListeners();
  }

  void applyClueHint() {
    _isHintUsed = true;
    _isClueRevealed = true;
    _audio.playClick();
    notifyListeners();
  }

  Future<void> nextQuestion() async {
    if (_currentIndex + 1 < _questions.length) {
      _currentIndex++;
      _resetQuestionState();
      _startTimer();
      notifyListeners();
    } else {
      // Quiz ended
      _timer?.cancel();
      _isQuizCompleted = true;
      _audio.playVictory();

      // Securely record rewards and save history
      if (_currentCategory != null) {
        await _walletService.recordQuizResult(
          categoryId: _currentCategory!.id,
          categoryTitle: _currentCategory!.title,
          questionsAttempted: _questions.length,
          correctAnswers: _correctCount,
          incorrectAnswers: _incorrectCount,
          pointsEarned: _pointsEarned,
        );
      }
      notifyListeners();
    }
  }

  void _resetQuestionState() {
    _selectedOption = -1;
    _isAnswerChecked = false;
    _eliminatedOptions.clear();
    _isClueRevealed = false;
    _isHintUsed = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
