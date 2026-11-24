class WalletModel {
  final String uid;
  final int totalPoints;
  final int availablePoints;
  final double availableBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final double pendingWithdrawals;

  WalletModel({
    required this.uid,
    this.totalPoints = 0,
    this.availablePoints = 0,
    this.availableBalance = 0.0,
    this.totalEarnings = 0.0,
    this.totalWithdrawn = 0.0,
    this.pendingWithdrawals = 0.0,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      uid: json['uid'] as String? ?? '',
      totalPoints: json['totalPoints'] as int? ?? 0,
      availablePoints: json['availablePoints'] as int? ?? 0,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      pendingWithdrawals: (json['pendingWithdrawals'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'availableBalance': availableBalance,
      'totalEarnings': totalEarnings,
      'totalWithdrawn': totalWithdrawn,
      'pendingWithdrawals': pendingWithdrawals,
    };
  }
}

class WalletTransaction {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int points;
  final double amount;
  final String type; // 'quiz_reward', 'withdrawal', 'bonus'
  final String status; // 'Completed', 'Pending', 'Rejected'
  final DateTime timestamp;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.points,
    required this.amount,
    required this.type,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'quiz_reward',
      status: json['status'] as String? ?? 'Completed',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'points': points,
      'amount': amount,
      'type': type,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class WithdrawalRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userMobile;
  final String upiId;
  final int pointsDeducted;
  final double amount;
  final String status; // 'Pending', 'Approved', 'Processing', 'Paid', 'Rejected'
  final DateTime requestDate;
  final DateTime? processedDate;
  final String? adminRemarks;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userMobile,
    required this.upiId,
    required this.pointsDeducted,
    required this.amount,
    required this.status,
    DateTime? requestDate,
    this.processedDate,
    this.adminRemarks,
  }) : requestDate = requestDate ?? DateTime.now();

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      userMobile: json['userMobile'] as String? ?? '',
      upiId: json['upiId'] as String? ?? '',
      pointsDeducted: json['pointsDeducted'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Pending',
      requestDate: json['requestDate'] != null
          ? DateTime.tryParse(json['requestDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      processedDate: json['processedDate'] != null
          ? DateTime.tryParse(json['processedDate'].toString())
          : null,
      adminRemarks: json['adminRemarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userMobile': userMobile,
      'upiId': upiId,
      'pointsDeducted': pointsDeducted,
      'amount': amount,
      'status': status,
      'requestDate': requestDate.toIso8601String(),
      'processedDate': processedDate?.toIso8601String(),
      'adminRemarks': adminRemarks,
    };
  }

  WithdrawalRequest copyWith({
    String? status,
    DateTime? processedDate,
    String? adminRemarks,
  }) {
    return WithdrawalRequest(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userMobile: userMobile,
      upiId: upiId,
      pointsDeducted: pointsDeducted,
      amount: amount,
      status: status ?? this.status,
      requestDate: requestDate,
      processedDate: processedDate ?? this.processedDate,
      adminRemarks: adminRemarks ?? this.adminRemarks,
    );
  }
}

class QuizHistoryItem {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryTitle;
  final int questionsAttempted;
  final int correctAnswers;
  final int pointsEarned;
  final DateTime date;

  QuizHistoryItem({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryTitle,
    required this.questionsAttempted,
    required this.correctAnswers,
    required this.pointsEarned,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  factory QuizHistoryItem.fromJson(Map<String, dynamic> json) {
    return QuizHistoryItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryTitle: json['categoryTitle'] as String? ?? '',
      questionsAttempted: json['questionsAttempted'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'categoryTitle': categoryTitle,
      'questionsAttempted': questionsAttempted,
      'correctAnswers': correctAnswers,
      'pointsEarned': pointsEarned,
      'date': date.toIso8601String(),
    };
  }
}

class AppSettingsModel {
  final int pointsPerRupee; // e.g. 100 points = 1 Rupee (1000 pts = ₹10)
  final int easyPoints;
  final int mediumPoints;
  final int hardPoints;
  final int expertPoints;
  final int masterPoints;
  final bool enableCashWithdrawals; // Default false as per legal & compliance rule
  final bool rewardedAdsEnabled;
  final bool interstitialAdsEnabled;
  final int minWithdrawalPoints;

  const AppSettingsModel({
    this.pointsPerRupee = 100,
    this.easyPoints = 5,
    this.mediumPoints = 10,
    this.hardPoints = 20,
    this.expertPoints = 30,
    this.masterPoints = 50,
    this.enableCashWithdrawals = false,
    this.rewardedAdsEnabled = true,
    this.interstitialAdsEnabled = true,
    this.minWithdrawalPoints = 100000,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      pointsPerRupee: json['pointsPerRupee'] as int? ?? 100,
      easyPoints: json['easyPoints'] as int? ?? 5,
      mediumPoints: json['mediumPoints'] as int? ?? 10,
      hardPoints: json['hardPoints'] as int? ?? 20,
      expertPoints: json['expertPoints'] as int? ?? 30,
      masterPoints: json['masterPoints'] as int? ?? 50,
      enableCashWithdrawals: json['enableCashWithdrawals'] as bool? ?? false,
      rewardedAdsEnabled: json['rewardedAdsEnabled'] as bool? ?? true,
      interstitialAdsEnabled: json['interstitialAdsEnabled'] as bool? ?? true,
      minWithdrawalPoints: json['minWithdrawalPoints'] as int? ?? 100000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointsPerRupee': pointsPerRupee,
      'easyPoints': easyPoints,
      'mediumPoints': mediumPoints,
      'hardPoints': hardPoints,
      'expertPoints': expertPoints,
      'masterPoints': masterPoints,
      'enableCashWithdrawals': enableCashWithdrawals,
      'rewardedAdsEnabled': rewardedAdsEnabled,
      'interstitialAdsEnabled': interstitialAdsEnabled,
      'minWithdrawalPoints': minWithdrawalPoints,
    };
  }

  AppSettingsModel copyWith({
    int? pointsPerRupee,
    int? easyPoints,
    int? mediumPoints,
    int? hardPoints,
    int? expertPoints,
    int? masterPoints,
    bool? enableCashWithdrawals,
    bool? rewardedAdsEnabled,
    bool? interstitialAdsEnabled,
    int? minWithdrawalPoints,
  }) {
    return AppSettingsModel(
      pointsPerRupee: pointsPerRupee ?? this.pointsPerRupee,
      easyPoints: easyPoints ?? this.easyPoints,
      mediumPoints: mediumPoints ?? this.mediumPoints,
      hardPoints: hardPoints ?? this.hardPoints,
      expertPoints: expertPoints ?? this.expertPoints,
      masterPoints: masterPoints ?? this.masterPoints,
      enableCashWithdrawals: enableCashWithdrawals ?? this.enableCashWithdrawals,
      rewardedAdsEnabled: rewardedAdsEnabled ?? this.rewardedAdsEnabled,
      interstitialAdsEnabled: interstitialAdsEnabled ?? this.interstitialAdsEnabled,
      minWithdrawalPoints: minWithdrawalPoints ?? this.minWithdrawalPoints,
    );
  }
}
