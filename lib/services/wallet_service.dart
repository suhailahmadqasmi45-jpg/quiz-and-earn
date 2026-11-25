import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  String? _activeUserId;

  AppSettingsModel get settings => _settings;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  List<WithdrawalRequest> get withdrawals => List.unmodifiable(_withdrawals);
  List<QuizHistoryItem> get quizHistory => List.unmodifiable(_quizHistory);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load app-wide settings
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
    // Ensure points conversion: 100 points = ₹1
    if (_settings.pointsPerRupee != 100) {
      _settings = _settings.copyWith(pointsPerRupee: 100);
    }

    // Check if an active user exists to load their isolated wallet
    final activeUid = prefs.getString('active_session_uid');
    if (activeUid != null && activeUid.isNotEmpty) {
      await loadForUser(activeUid);
    }
  }

  /// Loads wallet, transactions, and quiz history exclusively for the specified user UID
  Future<void> loadForUser(String uid) async {
    _activeUserId = uid;
    _transactions.clear();
    _withdrawals.clear();
    _quizHistory.clear();

    final prefs = await SharedPreferences.getInstance();

    // 1. Load user-specific transactions
    final txJson = prefs.getString('wallet_transactions_$uid');
    if (txJson != null && txJson.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(txJson);
        for (final item in list) {
          _transactions.add(WalletTransaction.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading transactions for $uid: $e');
      }
    }

    // 2. Load user-specific withdrawals
    final withJson = prefs.getString('withdrawal_requests_$uid');
    if (withJson != null && withJson.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(withJson);
        for (final item in list) {
          _withdrawals.add(WithdrawalRequest.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading withdrawals for $uid: $e');
      }
    }

    // 3. Load user-specific quiz history
    final histJson = prefs.getString('quiz_history_$uid');
    if (histJson != null && histJson.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(histJson);
        for (final item in list) {
          _quizHistory.add(QuizHistoryItem.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading quiz history for $uid: $e');
      }
    }
  }

  /// Clears in-memory wallet data on logout
  void clearUserData() {
    _activeUserId = null;
    _transactions.clear();
    _withdrawals.clear();
    _quizHistory.clear();
  }

  /// Deletes stored user wallet records on account deletion
  Future<void> deleteUserData(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wallet_transactions_$uid');
      await prefs.remove('withdrawal_requests_$uid');
      await prefs.remove('quiz_history_$uid');
    } catch (_) {}
    if (_activeUserId == uid) {
      clearUserData();
    }
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
    final uid = user?.uid ?? _activeUserId ?? 'anonymous';

    // 1. Update user total stats
    await AuthService().updateUserStats(
      quizPlayedDelta: 1,
      correctDelta: correctAnswers,
      incorrectDelta: incorrectAnswers,
      pointsDelta: pointsEarned,
    );

    final now = DateTime.now();

    // 2. Add quiz history item for this user
    final historyItem = QuizHistoryItem(
      id: 'QH-${const Uuid().v4().substring(0, 8)}',
      userId: uid,
      categoryId: categoryId,
      categoryTitle: categoryTitle,
      questionsAttempted: questionsAttempted,
      correctAnswers: correctAnswers,
      pointsEarned: pointsEarned,
      date: now,
    );
    _quizHistory.insert(0, historyItem);
    await _persistHistory(uid);

    // 3. Add wallet transaction if points were earned
    if (pointsEarned > 0) {
      final tx = WalletTransaction(
        id: 'TX-${const Uuid().v4().substring(0, 8)}',
        userId: uid,
        title: 'Quiz Reward: $categoryTitle',
        description: 'Earned $pointsEarned points ($correctAnswers/$questionsAttempted correct)',
        points: pointsEarned,
        amount: calculateRewardValue(pointsEarned),
        type: 'quiz_reward',
        status: 'Completed',
        timestamp: now,
      );
      _transactions.insert(0, tx);
      await _persistTransactions(uid);
    }
  }

  Future<void> recordDailyBonusTransaction({required int points}) async {
    final user = AuthService().currentUser;
    final uid = user?.uid ?? _activeUserId ?? 'anonymous';

    await AuthService().updateUserStats(
      quizPlayedDelta: 0,
      correctDelta: 0,
      incorrectDelta: 0,
      pointsDelta: points,
    );

    final tx = WalletTransaction(
      id: 'TX-${const Uuid().v4().substring(0, 8)}',
      userId: uid,
      title: 'Daily Check-in Bonus',
      description: 'Awarded $points daily engagement points',
      points: points,
      amount: calculateRewardValue(points),
      type: 'daily_bonus',
      status: 'Completed',
      timestamp: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _persistTransactions(uid);
  }

  Future<String?> submitWithdrawal({
    required int pointsToRedeem,
    required String upiId,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) {
      return 'Please sign in to request a withdrawal.';
    }

    if (upiId.trim().isEmpty) {
      return 'Please provide a valid UPI ID (e.g., name@okhdfcbank).';
    }

    if (pointsToRedeem < _settings.minWithdrawalPoints) {
      return 'Minimum withdrawal threshold is ${_settings.minWithdrawalPoints} points (₹${calculateRewardValue(_settings.minWithdrawalPoints).toStringAsFixed(0)}).';
    }

    if (pointsToRedeem > user.availablePoints) {
      return 'Insufficient balance. You currently have ${user.availablePoints} points.';
    }

    final double amount = calculateRewardValue(pointsToRedeem);
    final now = DateTime.now();
    final withId = 'WD-${const Uuid().v4().substring(0, 8)}';

    // 1. Create withdrawal request
    final req = WithdrawalRequest(
      id: withId,
      userId: user.uid,
      userName: user.name,
      userEmail: user.email,
      userMobile: user.mobile.isNotEmpty ? user.mobile : 'N/A',
      upiId: upiId.trim(),
      pointsDeducted: pointsToRedeem,
      amount: amount,
      status: 'Pending',
      requestDate: now,
    );
    _withdrawals.insert(0, req);
    await _persistWithdrawals(user.uid);

    // 2. Record ledger transaction
    final tx = WalletTransaction(
      id: 'TX-${const Uuid().v4().substring(0, 8)}',
      userId: user.uid,
      title: 'Withdrawal Initiated',
      description: 'Transfer of ₹${amount.toStringAsFixed(2)} to ${upiId.trim()}',
      points: -pointsToRedeem,
      amount: amount,
      type: 'withdrawal',
      status: 'Pending',
      timestamp: now,
    );
    _transactions.insert(0, tx);
    await _persistTransactions(user.uid);

    // 3. Deduct points from active user
    await AuthService().deductPointsForWithdrawal(pointsToRedeem, amount);

    return null; // Success!
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    _settings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings_v2', json.encode(newSettings.toJson()));
  }

  Future<void> updateWithdrawalStatus({
    required String requestId,
    required String newStatus,
    String? remarks,
  }) async {
    final index = _withdrawals.indexWhere((w) => w.id == requestId);
    if (index != -1) {
      final old = _withdrawals[index];
      _withdrawals[index] = WithdrawalRequest(
        id: old.id,
        userId: old.userId,
        userName: old.userName,
        userEmail: old.userEmail,
        userMobile: old.userMobile,
        upiId: old.upiId,
        pointsDeducted: old.pointsDeducted,
        amount: old.amount,
        status: newStatus,
        requestDate: old.requestDate,
        processedDate: DateTime.now(),
        adminRemarks: remarks ?? old.adminRemarks,
      );
      if (_activeUserId != null) {
        await _persistWithdrawals(_activeUserId!);
      }
    }
  }

  Future<void> _persistTransactions(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _transactions.map((t) => t.toJson()).toList();
    await prefs.setString('wallet_transactions_$uid', json.encode(list));
  }

  Future<void> _persistWithdrawals(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _withdrawals.map((w) => w.toJson()).toList();
    await prefs.setString('withdrawal_requests_$uid', json.encode(list));
  }

  Future<void> _persistHistory(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _quizHistory.map((h) => h.toJson()).toList();
    await prefs.setString('quiz_history_$uid', json.encode(list));
  }
}
