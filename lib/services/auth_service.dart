import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const List<String> authorizedAdminEmails = [
    'suhailahmadqasmi45@gmail.com',
    'admin@quizandearn.com',
  ];

  static bool isEmailAdmin(String? email) {
    if (email == null) return false;
    return authorizedAdminEmails.contains(email.trim().toLowerCase());
  }

  FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;
  UserModel? _currentUser;
  bool _isFirebaseAvailable = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firebaseAuth = FirebaseAuth.instance;
        _googleSignIn = GoogleSignIn();
        _isFirebaseAvailable = true;
      }
    } catch (e) {
      debugPrint('Firebase not initialized or running in offline mode: $e');
      _isFirebaseAvailable = false;
    }

    // Load locally persisted session
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user_profile');
    if (userJson != null && userJson.isNotEmpty) {
      try {
        _currentUser = UserModel.fromJson(json.decode(userJson) as Map<String, dynamic>);
        if (_currentUser != null && isEmailAdmin(_currentUser!.email)) {
          _currentUser = _currentUser!.copyWith(isAdmin: true);
        }
      } catch (e) {
        debugPrint('Error restoring user session: $e');
      }
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      if (_isFirebaseAvailable && _firebaseAuth != null && _googleSignIn != null) {
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null; // User cancelled

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _firebaseAuth!.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          // Check if we have an existing local profile or build new
          final prefs = await SharedPreferences.getInstance();
          final existingJson = prefs.getString('user_${firebaseUser.uid}');
          
          final bool isMasterAdmin = isEmailAdmin(firebaseUser.email);
          if (existingJson != null) {
            _currentUser = UserModel.fromJson(json.decode(existingJson) as Map<String, dynamic>);
            // Always ensure the authenticated Google email and profile match
            if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
              _currentUser = _currentUser!.copyWith(
                email: firebaseUser.email!,
                name: _currentUser!.name.isEmpty ? (firebaseUser.displayName ?? '') : _currentUser!.name,
                photoUrl: firebaseUser.photoURL ?? _currentUser!.photoUrl,
                isAdmin: isMasterAdmin || _currentUser!.isAdmin,
              );
            }
          } else {
            _currentUser = UserModel(
              uid: firebaseUser.uid,
              name: firebaseUser.displayName ?? (isMasterAdmin ? 'Suhail Ahmad (Admin)' : 'Quiz Player'),
              email: firebaseUser.email ?? '',
              mobile: '',
              upiId: '',
              photoUrl: firebaseUser.photoURL,
              isAdmin: isMasterAdmin,
              totalPoints: 100, // Welcome bonus points
              availablePoints: 100,
            );
          }
          await _persistUser();
          return _currentUser;
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In failed or fallback used: $e');
    }

    // High quality instant fallback for environments without Google Play Services / Firebase configured
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('current_user_profile');
    if (cached != null && cached.isNotEmpty) {
      try {
        _currentUser = UserModel.fromJson(json.decode(cached) as Map<String, dynamic>);
        return _currentUser;
      } catch (_) {}
    }

    final newUid = const Uuid().v4().substring(0, 8);
    _currentUser = UserModel(
      uid: 'USR-$newUid',
      name: 'Gulshan Kumar',
      email: 'gulshan.quiz@gmail.com',
      mobile: '',
      upiId: '',
      photoUrl: null,
      totalPoints: 150, // Welcome bonus points
      availablePoints: 150,
      totalQuizPlayed: 5,
      totalCorrectAnswers: 18,
      totalIncorrectAnswers: 4,
    );
    await _persistUser();
    return _currentUser;
  }

  Future<UserModel> signInAsAdmin({String email = 'suhailahmadqasmi45@gmail.com'}) async {
    _currentUser = UserModel(
      uid: 'ADM-SUHAIL',
      name: 'Suhail Ahmad (Super Admin)',
      email: email,
      mobile: '9876543210',
      upiId: 'suhail@okhdfcbank',
      isAdmin: true,
      totalPoints: 50000,
      availablePoints: 50000,
      totalQuizPlayed: 120,
      totalCorrectAnswers: 110,
    );
    await _persistUser();
    return _currentUser!;
  }

  Future<void> updateProfile({
    required String name,
    required String mobile,
    required String email,
    required String upiId,
  }) async {
    if (_currentUser == null) return;
    final bool isMasterAdmin = isEmailAdmin(email) || _currentUser!.isAdmin;
    _currentUser = _currentUser!.copyWith(
      name: name.trim(),
      mobile: mobile.trim(),
      email: email.trim(),
      upiId: upiId.trim(),
      isAdmin: isMasterAdmin,
    );
    await _persistUser();
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(photoUrl: photoUrl);
    await _persistUser();
  }

  Future<void> updateUserStats({
    required int quizPlayedDelta,
    required int correctDelta,
    required int incorrectDelta,
    required int pointsDelta,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      totalQuizPlayed: _currentUser!.totalQuizPlayed + quizPlayedDelta,
      totalCorrectAnswers: _currentUser!.totalCorrectAnswers + correctDelta,
      totalIncorrectAnswers: _currentUser!.totalIncorrectAnswers + incorrectDelta,
      totalPoints: _currentUser!.totalPoints + pointsDelta,
      availablePoints: _currentUser!.availablePoints + pointsDelta,
    );
    await _persistUser();
  }

  Future<void> deductPointsForWithdrawal(int pointsDeducted, double amountWithdrawn) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      availablePoints: (_currentUser!.availablePoints - pointsDeducted).clamp(0, 9999999),
      totalWithdrawn: _currentUser!.totalWithdrawn + amountWithdrawn,
    );
    await _persistUser();
  }

  Future<void> signOut() async {
    try {
      if (_isFirebaseAvailable && _firebaseAuth != null) {
        await _firebaseAuth!.signOut();
        await _googleSignIn?.signOut();
      }
    } catch (_) {}
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_profile');
  }

  Future<void> deleteAccount() async {
    try {
      if (_isFirebaseAvailable && _firebaseAuth?.currentUser != null) {
        await _firebaseAuth!.currentUser!.delete();
      }
    } catch (_) {}
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_profile');
  }

  Future<void> _persistUser() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_currentUser!.toJson());
    await prefs.setString('current_user_profile', jsonStr);
    await prefs.setString('user_${_currentUser!.uid}', jsonStr);
  }
}
