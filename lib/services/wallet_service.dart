import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet_model.dart';
import 'auth_service.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  AppSettingsModel _settings = const AppSettingsModel();
  final List<WalletTransaction> _transactions = [];
  final List<WithdrawalRequest> _withdrawals = [];
  final List<QuizHistoryItem> _quizHistory = [];

  AppSettingsModel get settings => _settings;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  List<WithdrawalRequest> get withdrawals => List.unmodifiable(_withdrawals);
  List<QuizHistoryItem> get quizHistory => List.unmodifiable(_quizHistory);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load settings
    final settingsJson = prefs.getString('app_settings');
    if (settingsJson != null) {
      try {
        _settings = AppSettingsModel.fromJson(json.decode(settingsJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    // Ensure minimum withdrawal points is at least 100,000 (₹1,000)
    if (_settings.minWithdrawalPoints < 100000) {
      _settings = _settings.copyWith(minWithdrawalPoints: 100000);
    }

    // Load transactions
    final txJson = prefs.getString('wallet_transactions');
    if (txJson != null) {
      try {
        final List<dynamic> list = json.decode(txJson);
        _transactions.clear();
        for (final item in list) {
          _transactions.add(WalletTransaction.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {}
    }

    // Load withdrawal requests
    final withJson = prefs.getString('withdrawal_requests');
    if (withJson != null) {
      try {
        final List<dynamic> list = json.decode(withJson);
        _withdrawals.clear();
        for (final item in list) {
          _withdrawals.add(WithdrawalRequest.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {}
    }

    // Load quiz history
    final histJson = prefs.getString('quiz_history');
    if (histJson != null) {
      try {
        final List<dynamic> list = json.decode(histJson);
        _quizHistory.clear();
        for (final item in list) {
          _quizHistory.add(QuizHistoryItem.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {}
    }

    // Seed default sample data if empty for a vivid out-of-the-box user experience
    if (_transactions.isEmpty) {
      _seedInitialData();
    }
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _transactions.addAll([
      WalletTransaction(
        id: 'TX-1001',
        userId: 'usr_current',
        title: 'Welcome Bonus Reward',
        description: 'New player joining bonus points',
        points: 100,
        amount: 1.0,
        type: 'bonus',
        status: 'Completed',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      WalletTransaction(
        id: 'TX-1002',
        userId: 'usr_current',
        title: 'Quiz Victory: General Knowledge',
        description: 'Scored 100% in Easy Level Round',
        points: 50,
        amount: 0.5,
        type: 'quiz_reward',
        status: 'Completed',
        timestamp: now.subtract(const Duration(hours: 14)),
      ),
    ]);

    _quizHistory.addAll([
      QuizHistoryItem(
        id: 'QH-001',
        userId: 'usr_current',
        categoryId: 'gk',
        categoryTitle: 'General Knowledge',
        questionsAttempted: 10,
        correctAnswers: 10,
        pointsEarned: 50,
        date: now.subtract(const Duration(hours: 14)),
      ),
      QuizHistoryItem(
        id: 'QH-002',
        userId: 'usr_current',
        categoryId: 'science',
        categoryTitle: 'Science & Technology',
        questionsAttempted: 10,
        correctAnswers: 8,
        pointsEarned: 40,
        date: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  double calculateRewardValue(int points) {
    if (_settings.pointsPerRupee <= 0) return 0.0;
    return points / _settings.pointsPerRupee;
  }

  Future<void> recordQuizResult({
    required String categoryId,
    required String categoryTitle,
    required int questionsAttempted,
    required int correctAnswers,
    required int incorrectAnswers,
    required int pointsEarned,
  }) async {
    final user = AuthService().currentUser;
    final uid = user?.uid ?? 'anonymous';

    // 1. Update user total stats
    await AuthService().updateUserStats(
      quizPlayedDelta: 1,
      correctDelta: correctAnswers,
      incorrectDelta: incorrectAnswers,
      pointsDelta: pointsEarned,
    );

    // 2. Add Transaction
    if (pointsEarned > 0) {
      final tx = WalletTransaction(
        id: 'TX-${const Uuid().v4().substring(0, 8).toUpperCase()}',
        userId: uid,
        title: 'Quiz Reward: $categoryTitle',
        description: '$correctAnswers/$questionsAttempted correct answers',
        points: pointsEarned,
        amount: calculateRewardValue(pointsEarned),
        type: 'quiz_reward',
        status: 'Completed',
      );
      _transactions.insert(0, tx);
      await _persistTransactions();
    }

    // 3. Add Quiz History
    final history = QuizHistoryItem(
      id: 'QH-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      userId: uid,
      categoryId: categoryId,
      categoryTitle: categoryTitle,
      questionsAttempted: questionsAttempted,
      correctAnswers: correctAnswers,
      pointsEarned: pointsEarned,
    );
    _quizHistory.insert(0, history);
    await _persistQuizHistory();
  }

  Future<void> recordDailyBonusTransaction({required int points}) async {
    final user = AuthService().currentUser;
    final uid = user?.uid ?? 'anonymous';

    // 1. Update user total stats
    await AuthService().updateUserStats(
      quizPlayedDelta: 0,
      correctDelta: 0,
      incorrectDelta: 0,
      pointsDelta: points,
    );

    // 2. Add Transaction
    final tx = WalletTransaction(
      id: 'TX-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      userId: uid,
      title: 'Daily Bonus Reward',
      description: 'Daily streak check-in reward',
      points: points,
      amount: calculateRewardValue(points),
      type: 'bonus',
      status: 'Completed',
    );
    _transactions.insert(0, tx);
    await _persistTransactions();
  }

  Future<String?> submitWithdrawal({
    required int pointsToRedeem,
    required String upiId,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) {
      return 'Please sign in to submit a withdrawal request.';
    }

    if (!_settings.enableCashWithdrawals) {
      return 'Cash redemptions are currently suspended pending regulatory compliance.';
    }

    if (pointsToRedeem < _settings.minWithdrawalPoints) {
      return 'Minimum withdrawal requirement is ${_settings.minWithdrawalPoints} points (₹${calculateRewardValue(_settings.minWithdrawalPoints).toStringAsFixed(0)}).';
    }

    if (user.availablePoints < pointsToRedeem) {
      return 'Insufficient points in wallet. You have ${user.availablePoints} points.';
    }

    final cleanUpi = upiId.trim();
    if (!cleanUpi.contains('@') || cleanUpi.length < 5) {
      return 'Please enter a valid UPI ID (e.g., yourname@bank).';
    }

    final double amount = calculateRewardValue(pointsToRedeem);
    final reqId = 'WREQ-${const Uuid().v4().substring(0, 8).toUpperCase()}';

    // Deduct points from user
    await AuthService().deductPointsForWithdrawal(pointsToRedeem, amount);

    final req = WithdrawalRequest(
      id: reqId,
      userId: user.uid,
      userName: user.name,
      userEmail: user.email,
      userMobile: user.mobile,
      upiId: cleanUpi,
      pointsDeducted: pointsToRedeem,
      amount: amount,
      status: 'Pending',
    );
    _withdrawals.insert(0, req);
    await _persistWithdrawals();

    // Create wallet transaction
    final tx = WalletTransaction(
      id: 'TX-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      userId: user.uid,
      title: 'UPI Withdrawal Request',
      description: 'Request #$reqId to $cleanUpi',
      points: -pointsToRedeem,
      amount: -amount,
      type: 'withdrawal',
      status: 'Pending',
    );
    _transactions.insert(0, tx);
    await _persistTransactions();

    return null; // Success (no error)
  }

  Future<void> updateWithdrawalStatus({
    required String requestId,
    required String newStatus,
    String? remarks,
  }) async {
    final idx = _withdrawals.indexWhere((w) => w.id == requestId);
    if (idx >= 0) {
      _withdrawals[idx] = _withdrawals[idx].copyWith(
        status: newStatus,
        processedDate: DateTime.now(),
        adminRemarks: remarks,
      );
      await _persistWithdrawals();
    }
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    _settings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', json.encode(newSettings.toJson()));
  }

  Future<void> _persistTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _transactions.map((t) => t.toJson()).toList();
    await prefs.setString('wallet_transactions', json.encode(list));
  }

  Future<void> _persistWithdrawals() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _withdrawals.map((w) => w.toJson()).toList();
    await prefs.setString('withdrawal_requests', json.encode(list));
  }

  Future<void> _persistQuizHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _quizHistory.map((q) => q.toJson()).toList();
    await prefs.setString('quiz_history', json.encode(list));
  }
}
