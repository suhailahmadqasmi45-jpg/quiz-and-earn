import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'wallet_service.dart';
import 'cloud_sync_service.dart';
import '../repositories/quiz_repository.dart';

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
        _isFirebaseAvailable = true;
      }
    } catch (e) {
      debugPrint('Firebase initialization notice in AuthService: $e');
      _isFirebaseAvailable = false;
    }

    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

    // Restore isolated user session if an active UID is saved
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeUid = prefs.getString('active_session_uid');
      if (activeUid != null && activeUid.isNotEmpty) {
        final profileJson = prefs.getString('user_profile_$activeUid');
        if (profileJson != null && profileJson.isNotEmpty) {
          _currentUser = UserModel.fromJson(json.decode(profileJson) as Map<String, dynamic>);
          if (_currentUser != null && isEmailAdmin(_currentUser!.email)) {
            _currentUser = _currentUser!.copyWith(isAdmin: true);
          }
          // Load user-scoped wallet and seen questions
          await WalletService().loadForUser(activeUid);
          await QuizRepository().loadSeenQuestionsForUser(activeUid);
          // Sync active session to AWS DynamoDB
          CloudSyncService().syncUser(_currentUser!).catchError((_) => false);
        }
      }
    } catch (e) {
      debugPrint('Error restoring user session: $e');
    }
  }

  /// Authenticates user with Google and isolates all account data by UID
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Disconnect/signOut prior GoogleSignIn session so account picker always opens,
      // enabling true multi-account switching!
      try {
        await _googleSignIn?.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
      if (googleUser == null) {
        // User voluntarily dismissed or cancelled the Google account picker
        return null;
      }

      String uid = 'google_${googleUser.id}';
      String name = googleUser.displayName ?? '';
      String email = googleUser.email.trim();
      String? photoUrl = googleUser.photoUrl;

      // Attempt Firebase credential exchange if Firebase is available
      if (_isFirebaseAvailable && _firebaseAuth != null) {
        try {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final UserCredential userCredential = await _firebaseAuth!.signInWithCredential(credential);
          final User? fbUser = userCredential.user;
          if (fbUser != null) {
            uid = fbUser.uid;
            if (fbUser.displayName != null && fbUser.displayName!.isNotEmpty) {
              name = fbUser.displayName!;
            }
            if (fbUser.email != null && fbUser.email!.isNotEmpty) {
              email = fbUser.email!;
            }
            if (fbUser.photoURL != null && fbUser.photoURL!.isNotEmpty) {
              photoUrl = fbUser.photoURL;
            }
          }
        } catch (fbErr) {
          debugPrint('Firebase signInWithCredential notice: $fbErr');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final bool isMasterAdmin = isEmailAdmin(email);

      // Check if this specific user UID already has an isolated stored profile
      final existingProfileJson = prefs.getString('user_profile_$uid');
      if (existingProfileJson != null && existingProfileJson.isNotEmpty) {
        try {
          final existing = UserModel.fromJson(json.decode(existingProfileJson) as Map<String, dynamic>);
          _currentUser = existing.copyWith(
            email: email,
            name: existing.name.isNotEmpty ? existing.name : (name.isNotEmpty ? name : 'Quiz Player'),
            photoUrl: photoUrl ?? existing.photoUrl,
            isAdmin: isMasterAdmin || existing.isAdmin,
          );
        } catch (_) {
          _currentUser = UserModel(
            uid: uid,
            name: name.isNotEmpty ? name : 'Quiz Player',
            email: email,
            mobile: '',
            upiId: '',
            photoUrl: photoUrl,
            isAdmin: isMasterAdmin,
            totalPoints: 0,
            availablePoints: 0,
          );
        }
      } else {
        // Brand new isolated user: completely empty profile, 0 points
        _currentUser = UserModel(
          uid: uid,
          name: name.isNotEmpty ? name : 'Quiz Player',
          email: email,
          mobile: '',
          upiId: '',
          photoUrl: photoUrl,
          isAdmin: isMasterAdmin,
          totalPoints: 0,
          availablePoints: 0,
        );
      }

      // Persist active session and user profile
      await _persistCurrentUser();

      // Load this user's isolated wallet, transactions, and question history
      await WalletService().loadForUser(uid);
      await QuizRepository().loadSeenQuestionsForUser(uid);

      return _currentUser;
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      return null;
    }
  }

  Future<UserModel> signInAsAdmin({String email = 'suhailahmadqasmi45@gmail.com'}) async {
    const adminUid = 'ADM-ADMIN-PORTAL';
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('user_profile_$adminUid');
    if (existingJson != null) {
      try {
        _currentUser = UserModel.fromJson(json.decode(existingJson) as Map<String, dynamic>);
        _currentUser = _currentUser!.copyWith(isAdmin: true);
      } catch (_) {}
    }
    _currentUser ??= UserModel(
        uid: adminUid,
        name: 'Admin Console',
        email: email,
        mobile: '9876543210',
        upiId: 'admin@okhdfcbank',
        isAdmin: true,
        totalPoints: 50000,
        availablePoints: 50000,
        totalQuizPlayed: 50,
        totalCorrectAnswers: 45,
      );
    await _persistCurrentUser();
    await WalletService().loadForUser(adminUid);
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
    await _persistCurrentUser();
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(photoUrl: photoUrl);
    await _persistCurrentUser();
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
    await _persistCurrentUser();
  }

  Future<void> deductPointsForWithdrawal(int pointsDeducted, double amountWithdrawn) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      availablePoints: (_currentUser!.availablePoints - pointsDeducted).clamp(0, 9999999),
      totalWithdrawn: _currentUser!.totalWithdrawn + amountWithdrawn,
    );
    await _persistCurrentUser();
  }

  /// Complete logout clearing all active session references
  Future<void> signOut() async {
    try {
      if (_isFirebaseAvailable && _firebaseAuth != null) {
        await _firebaseAuth!.signOut();
      }
      await _googleSignIn?.signOut();
    } catch (_) {}

    final uid = _currentUser?.uid;
    debugPrint('Signing out user $uid');
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_session_uid');
    await prefs.remove('current_user_profile'); // clean legacy key

    // Reset user-scoped services
    WalletService().clearUserData();
    QuizRepository().clearActiveUser();
  }

  /// Deletes user data and resets session completely
  Future<void> deleteAccount() async {
    final uid = _currentUser?.uid;
    try {
      if (_isFirebaseAvailable && _firebaseAuth?.currentUser != null) {
        await _firebaseAuth!.currentUser!.delete();
      }
      await _googleSignIn?.signOut();
    } catch (_) {}

    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_$uid');
      await prefs.remove('active_session_uid');
      await prefs.remove('current_user_profile');
      await WalletService().deleteUserData(uid);
      await QuizRepository().clearSeenQuestionsForUser(uid);
    }

    _currentUser = null;
    WalletService().clearUserData();
    QuizRepository().clearActiveUser();
  }

  Future<void> _persistCurrentUser() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_currentUser!.toJson());
    await prefs.setString('active_session_uid', _currentUser!.uid);
    await prefs.setString('user_profile_${_currentUser!.uid}', jsonStr);
    await prefs.setString('user_${_currentUser!.uid}', jsonStr);
    // Sync to Cloud Firestore in background so new users are instantly visible in Admin Console
    CloudSyncService().syncUser(_currentUser!).catchError((e) {
      debugPrint('Cloud user sync notice: $e');
      return false;
    });
  }
}
