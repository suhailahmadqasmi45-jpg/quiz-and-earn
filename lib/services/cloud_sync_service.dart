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
  Future<bool> syncUser(UserModel user) async {
    final email = user.email.isNotEmpty ? user.email.trim() : user.uid.trim();
    if (email.isEmpty) return false;

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
      };

      request.write(json.encode(body));
      final response = await request.close();
      final respText = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        debugPrint('CloudSyncService: User $email synced to AWS DynamoDB.');
        return true;
      } else {
        debugPrint('CloudSyncService: syncUser returned ${response.statusCode}: $respText');
        return false;
      }
    } catch (e) {
      debugPrint('CloudSyncService: syncUser failed gracefully: $e');
      return false;
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

      request.write(json.encode(body));
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
