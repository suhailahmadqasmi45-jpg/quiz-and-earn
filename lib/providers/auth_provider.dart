import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await _authService.init();
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signInAsAdmin() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signInAsAdmin();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String mobile,
    required String email,
    required String upiId,
  }) async {
    _isLoading = true;
    notifyListeners();
    await _authService.updateProfile(
      name: name,
      mobile: mobile,
      email: email,
      upiId: upiId,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    _isLoading = true;
    notifyListeners();
    await _authService.updatePhotoUrl(photoUrl);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserStats({
    int quizPlayedDelta = 0,
    int correctDelta = 0,
    int incorrectDelta = 0,
    int pointsDelta = 0,
  }) async {
    await _authService.updateUserStats(
      quizPlayedDelta: quizPlayedDelta,
      correctDelta: correctDelta,
      incorrectDelta: incorrectDelta,
      pointsDelta: pointsDelta,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    await _authService.deleteAccount();
    _isLoading = false;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
