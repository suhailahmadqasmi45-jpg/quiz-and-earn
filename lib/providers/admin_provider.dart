import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/question_model.dart';
import '../models/wallet_model.dart';
import '../repositories/quiz_repository.dart';
import '../services/wallet_service.dart';
import '../services/admob_service.dart';

class AdminProvider with ChangeNotifier {
  final QuizRepository _quizRepo = QuizRepository();
  final WalletService _walletService = WalletService();
  final AdMobService _admob = AdMobService();

  final List<UserModel> _users = [
    UserModel(
      uid: 'USR-8901',
      name: 'Rohan Sharma',
      email: 'rohan.player@gmail.com',
      mobile: '9876543210',
      upiId: 'rohan@okhdfcbank',
      totalQuizPlayed: 32,
      totalCorrectAnswers: 280,
      totalPoints: 3400,
      availablePoints: 2400,
      totalWithdrawn: 10.0,
    ),
    UserModel(
      uid: 'USR-8902',
      name: 'Aakash Sharma',
      email: 'aakash.sharma@gmail.com',
      mobile: '9811223344',
      upiId: 'aakash@oksbi',
      totalQuizPlayed: 45,
      totalCorrectAnswers: 390,
      totalPoints: 5200,
      availablePoints: 5200,
      totalWithdrawn: 0.0,
    ),
    UserModel(
      uid: 'USR-8903',
      name: 'Priya Verma',
      email: 'priya.verma@outlook.com',
      mobile: '9711556677',
      upiId: 'priya@paytm',
      totalQuizPlayed: 28,
      totalCorrectAnswers: 210,
      totalPoints: 2600,
      availablePoints: 1600,
      totalWithdrawn: 10.0,
    ),
    UserModel(
      uid: 'USR-8904',
      name: 'Rahul Patel',
      email: 'rahul.patel@gmail.com',
      mobile: '9922446688',
      upiId: 'rahul@icici',
      totalQuizPlayed: 14,
      totalCorrectAnswers: 98,
      totalPoints: 1200,
      availablePoints: 1200,
      totalWithdrawn: 0.0,
    ),
  ];

  List<UserModel> get users => List.unmodifiable(_users);
  List<QuestionModel> get questions => _quizRepo.allQuestions;
  List<WithdrawalRequest> get withdrawals => _walletService.withdrawals;
  AppSettingsModel get settings => _walletService.settings;

  // Stats
  int get totalUsersCount => _users.length + 152; // Active player community
  int get totalQuizzesPlayed => _users.fold(0, (sum, u) => sum + u.totalQuizPlayed) + 1420;
  int get totalCorrectAnswers => _users.fold(0, (sum, u) => sum + u.totalCorrectAnswers) + 9850;
  int get totalPointsDistributed => _users.fold(0, (sum, u) => sum + u.totalPoints) + 124000;
  double get totalRewardValue => _walletService.calculateRewardValue(totalPointsDistributed);
  int get pendingWithdrawalsCount => _walletService.withdrawals.where((w) => w.status == 'Pending').length;

  Future<void> saveQuestion(QuestionModel question) async {
    await _quizRepo.saveQuestion(question);
    notifyListeners();
  }

  Future<void> deleteQuestion(String questionId) async {
    await _quizRepo.deleteQuestion(questionId);
    notifyListeners();
  }

  Future<void> toggleQuestionPublish(String questionId) async {
    await _quizRepo.togglePublish(questionId);
    notifyListeners();
  }

  Future<void> updateWithdrawalStatus(String requestId, String newStatus, {String? remarks}) async {
    await _walletService.updateWithdrawalStatus(
      requestId: requestId,
      newStatus: newStatus,
      remarks: remarks,
    );
    notifyListeners();
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    await _walletService.updateSettings(newSettings);
    _admob.isRewardedAdsEnabled = newSettings.rewardedAdsEnabled;
    _admob.isInterstitialAdsEnabled = newSettings.interstitialAdsEnabled;
    notifyListeners();
  }
}
