import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  static const String projectId = 'quiz-and-earn-63428';
  static const String apiKey = 'AIzaSyDHcoQIQtqo92gorMOQiFqlROPwdCrM8Ic';
  static const String firestoreBaseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  /// Synchronizes the user profile, stats, and wallet points to Cloud Firestore
  Future<bool> syncUser(UserModel user) async {
    if (user.uid.isEmpty) return false;

    try {
      final url = Uri.parse('$firestoreBaseUrl/users/${user.uid}?key=$apiKey');
      final request = await _client.patchUrl(url);
      request.headers.contentType = ContentType.json;

      final body = {
        'fields': {
          'uid': {'stringValue': user.uid},
          'name': {'stringValue': user.name.isNotEmpty ? user.name : 'Quiz Player'},
          'email': {'stringValue': user.email},
          'mobile': {'stringValue': user.mobile},
          'upiId': {'stringValue': user.upiId},
          'photoUrl': {'stringValue': user.photoUrl ?? ''},
          'totalPoints': {'integerValue': user.totalPoints.toString()},
          'availablePoints': {'integerValue': user.availablePoints.toString()},
          'totalQuizPlayed': {'integerValue': user.totalQuizPlayed.toString()},
          'totalCorrectAnswers': {'integerValue': user.totalCorrectAnswers.toString()},
          'isAdmin': {'booleanValue': user.isAdmin},
          'lastSeen': {'stringValue': DateTime.now().toIso8601String()},
          'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
        }
      };

      request.write(json.encode(body));
      final response = await request.close();
      final respText = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        debugPrint('CloudSyncService: User ${user.email} synced successfully to cloud.');
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

  /// Synchronizes a withdrawal redemption request to Cloud Firestore
  Future<bool> syncWithdrawal(WithdrawalRequest req, UserModel user) async {
    try {
      final url = Uri.parse('$firestoreBaseUrl/withdrawals/${req.id}?key=$apiKey');
      final request = await _client.patchUrl(url);
      request.headers.contentType = ContentType.json;

      final body = {
        'fields': {
          'id': {'stringValue': req.id},
          'userId': {'stringValue': req.userId},
          'userName': {'stringValue': req.userName.isNotEmpty ? req.userName : user.name},
          'userEmail': {'stringValue': req.userEmail.isNotEmpty ? req.userEmail : user.email},
          'userMobile': {'stringValue': req.userMobile.isNotEmpty ? req.userMobile : user.mobile},
          'upiId': {'stringValue': req.upiId},
          'pointsDeducted': {'integerValue': req.pointsDeducted.toString()},
          'amount': {'doubleValue': req.amount},
          'status': {'stringValue': req.status},
          'requestDate': {'stringValue': req.requestDate.toIso8601String()},
          'utr': {'stringValue': ''},
        }
      };

      request.write(json.encode(body));
      final response = await request.close();

      if (response.statusCode == 200) {
        debugPrint('CloudSyncService: Withdrawal ${req.id} synced to cloud.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CloudSyncService: syncWithdrawal failed: $e');
      return false;
    }
  }
}
