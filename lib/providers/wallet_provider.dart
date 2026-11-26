import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  WalletProvider() {
    // React immediately whenever wallet transactions or withdrawals update
    _walletService.onWalletUpdated = () {
      notifyListeners();
    };
    // React immediately whenever user stats or points update in AuthService
    final previousOnUserUpdated = _authService.onUserUpdated;
    _authService.onUserUpdated = () {
      previousOnUserUpdated?.call();
      notifyListeners();
    };
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AppSettingsModel get settings => _walletService.settings;
  List<WalletTransaction> get transactions => _walletService.transactions;
  List<WithdrawalRequest> get withdrawals => _walletService.withdrawals;
  List<QuizHistoryItem> get quizHistory => _walletService.quizHistory;

  int get availablePoints => _authService.currentUser?.availablePoints ?? 0;
  int get totalPoints => _authService.currentUser?.totalPoints ?? 0;
  double get totalWithdrawn => _authService.currentUser?.totalWithdrawn ?? 0.0;
  
  double get availableBalance => _walletService.calculateRewardValue(availablePoints);
  double get totalEarningsValue => _walletService.calculateRewardValue(totalPoints);

  double get pendingWithdrawalsTotal {
    return _walletService.withdrawals
        .where((w) => w.status == 'Pending' || w.status == 'Processing')
        .fold(0.0, (sum, w) => sum + w.amount);
  }

  Future<void> init() async {
    await _walletService.init();
    notifyListeners();
  }

  /// Pulls the latest wallet balance and points directly from AWS DynamoDB
  Future<void> refreshFromCloud() async {
    final user = _authService.currentUser;
    if (user != null && user.email.isNotEmpty) {
      try {
        final cloudUser = await CloudSyncService().fetchUser(user.email, baseUser: user);
        if (cloudUser != null) {
          final ptsDelta = cloudUser.availablePoints - user.availablePoints;
          if (ptsDelta > 0 || cloudUser.totalQuizPlayed > user.totalQuizPlayed) {
            await _authService.updateUserStats(
              quizPlayedDelta: (cloudUser.totalQuizPlayed - user.totalQuizPlayed).clamp(0, 999999),
              correctDelta: (cloudUser.totalCorrectAnswers - user.totalCorrectAnswers).clamp(0, 999999),
              incorrectDelta: 0,
              pointsDelta: ptsDelta > 0 ? ptsDelta : 0,
            );
          }
          await _walletService.syncCloudPointsToWallet(user.uid, cloudUser.availablePoints);
        }
      } catch (e) {
        debugPrint('refreshFromCloud notice: $e');
      }
      notifyListeners();
    }
  }

  Future<bool> submitWithdrawal({
    required int pointsToRedeem,
    required String upiId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await _walletService.submitWithdrawal(
      pointsToRedeem: pointsToRedeem,
      upiId: upiId,
    );

    _isLoading = false;
    _errorMessage = error;
    notifyListeners();

    return error == null;
  }

  Future<void> claimDailyBonus(int points) async {
    await _walletService.recordDailyBonusTransaction(points: points);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
