import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  /// AWS Native DynamoDB + Lambda Function URL in eu-north-1
  static const String awsBackendUrl =
      'https://4jeem3lydxmrw3kspezhw7sbdm0uvolu.lambda-url.eu-north-1.on.aws';

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  /// Synchronizes the user profile, stats, and wallet points to AWS DynamoDB
  /// Returns the updated UserModel with latest points and stats from cloud
  Future<UserModel?> syncUser(UserModel user, {bool isFreshLogin = false}) async {
    final email = user.email.isNotEmpty ? user.email.trim().toLowerCase() : user.uid.trim();
    if (email.isEmpty) return user;

    try {
      final url = Uri.parse('$awsBackendUrl/sync-user');
      final request = await _client.postUrl(url);
      request.headers.contentType = ContentType.json;

      final body = {
        'uid': user.uid,
        'name': user.name.isNotEmpty ? user.name : 'Quiz Player',
        'email': email,
        'mobile': user.mobile,
        'upiId': user.upiId,
        'photoUrl': user.photoUrl ?? '',
        'coins': user.availablePoints,
        'coinsEarned': user.totalPoints,
        'quizzesPlayed': user.totalQuizPlayed,
        'correctAnswers': user.totalCorrectAnswers,
        'isAdmin': user.isAdmin,
        'isFreshLogin': isFreshLogin,
      };

      final bytes = utf8.encode(json.encode(body));
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close();
      final respText = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(respText) as Map<String, dynamic>;
        if (data['success'] == true && data['user'] != null) {
          final u = data['user'] as Map<String, dynamic>;
          final mergedUser = user.copyWith(
            availablePoints: u['coins'] is int ? u['coins'] as int : (u['coins'] as num?)?.toInt() ?? user.availablePoints,
            totalPoints: u['coinsEarned'] is int ? u['coinsEarned'] as int : (u['coinsEarned'] as num?)?.toInt() ?? user.totalPoints,
            totalQuizPlayed: u['quizzesPlayed'] is int ? u['quizzesPlayed'] as int : (u['quizzesPlayed'] as num?)?.toInt() ?? user.totalQuizPlayed,
            totalCorrectAnswers: u['correctAnswers'] is int ? u['correctAnswers'] as int : (u['correctAnswers'] as num?)?.toInt() ?? user.totalCorrectAnswers,
            name: (u['name'] as String?)?.isNotEmpty == true ? u['name'] as String : user.name,
            mobile: (u['mobile'] as String?)?.isNotEmpty == true ? u['mobile'] as String : user.mobile,
            upiId: (u['upiId'] as String?)?.isNotEmpty == true ? u['upiId'] as String : user.upiId,
          );
          debugPrint('CloudSyncService: User $email synced. Available points: ${mergedUser.availablePoints}');
          return mergedUser;
        }
      } else {
        debugPrint('CloudSyncService: syncUser returned ${response.statusCode}: $respText');
      }
      return user;
    } catch (e) {
      debugPrint('CloudSyncService: syncUser error: $e');
      return user;
    }
  }

  /// Fetches the user profile and reward points directly from AWS DynamoDB
  Future<UserModel?> fetchUser(String email, {UserModel? baseUser}) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    try {
      final url = Uri.parse('$awsBackendUrl/get-user?email=${Uri.encodeComponent(cleanEmail)}');
      final request = await _client.getUrl(url);
      final response = await request.close();
      final respText = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(respText) as Map<String, dynamic>;
        if (data['success'] == true && data['exists'] == true && data['user'] != null) {
          final u = data['user'] as Map<String, dynamic>;
          final current = baseUser ?? UserModel(
            uid: cleanEmail,
            name: (u['name'] as String?) ?? 'Quiz Player',
            email: cleanEmail,
            mobile: (u['mobile'] as String?) ?? '',
            upiId: (u['upiId'] as String?) ?? '',
            photoUrl: u['photoUrl'] as String?,
          );

          return current.copyWith(
            availablePoints: u['coins'] is int ? u['coins'] as int : (u['coins'] as num?)?.toInt() ?? 0,
            totalPoints: u['coinsEarned'] is int ? u['coinsEarned'] as int : (u['coinsEarned'] as num?)?.toInt() ?? 0,
            totalQuizPlayed: u['quizzesPlayed'] is int ? u['quizzesPlayed'] as int : (u['quizzesPlayed'] as num?)?.toInt() ?? 0,
            totalCorrectAnswers: u['correctAnswers'] is int ? u['correctAnswers'] as int : (u['correctAnswers'] as num?)?.toInt() ?? 0,
            name: (u['name'] as String?)?.isNotEmpty == true ? u['name'] as String : current.name,
            mobile: (u['mobile'] as String?)?.isNotEmpty == true ? u['mobile'] as String : current.mobile,
            upiId: (u['upiId'] as String?)?.isNotEmpty == true ? u['upiId'] as String : current.upiId,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('CloudSyncService: fetchUser error: $e');
      return null;
    }
  }

  /// Synchronizes a withdrawal redemption request to AWS DynamoDB
  Future<bool> syncWithdrawal(WithdrawalRequest req, UserModel user) async {
    try {
      final url = Uri.parse('$awsBackendUrl/sync-withdrawal');
      final request = await _client.postUrl(url);
      request.headers.contentType = ContentType.json;

      final body = {
        'id': req.id,
        'userId': req.userId,
        'userName': req.userName.isNotEmpty ? req.userName : user.name,
        'userEmail': req.userEmail.isNotEmpty ? req.userEmail : user.email,
        'userMobile': req.userMobile.isNotEmpty ? req.userMobile : user.mobile,
        'upiId': req.upiId,
        'coinsDeducted': req.pointsDeducted,
        'amount': req.amount,
        'status': req.status,
        'createdAt': req.requestDate.toIso8601String(),
        'utrNumber': '',
      };

      final bytes = utf8.encode(json.encode(body));
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close();

      if (response.statusCode == 200) {
        debugPrint('CloudSyncService: Withdrawal ${req.id} synced to AWS DynamoDB.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CloudSyncService: syncWithdrawal failed: $e');
      return false;
    }
  }
}
