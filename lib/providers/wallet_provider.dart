import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

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
