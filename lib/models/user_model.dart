class UserModel {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String upiId;
  final String? photoUrl;
  final int totalQuizPlayed;
  final int totalCorrectAnswers;
  final int totalIncorrectAnswers;
  final int totalPoints;
  final int availablePoints;
  final double totalWithdrawn;
  final DateTime memberSince;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
    required this.upiId,
    this.photoUrl,
    this.totalQuizPlayed = 0,
    this.totalCorrectAnswers = 0,
    this.totalIncorrectAnswers = 0,
    this.totalPoints = 0,
    this.availablePoints = 0,
    this.totalWithdrawn = 0.0,
    DateTime? memberSince,
    this.isAdmin = false,
  }) : memberSince = memberSince ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Quiz Player',
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      upiId: json['upiId'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      totalQuizPlayed: json['totalQuizPlayed'] as int? ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] as int? ?? 0,
      totalIncorrectAnswers: json['totalIncorrectAnswers'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      availablePoints: json['availablePoints'] as int? ?? 0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      memberSince: json['memberSince'] != null
          ? DateTime.tryParse(json['memberSince'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'mobile': mobile,
      'upiId': upiId,
      'photoUrl': photoUrl,
      'totalQuizPlayed': totalQuizPlayed,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalIncorrectAnswers': totalIncorrectAnswers,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'totalWithdrawn': totalWithdrawn,
      'memberSince': memberSince.toIso8601String(),
      'isAdmin': isAdmin,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? mobile,
    String? upiId,
    String? photoUrl,
    int? totalQuizPlayed,
    int? totalCorrectAnswers,
    int? totalIncorrectAnswers,
    int? totalPoints,
    int? availablePoints,
    double? totalWithdrawn,
    DateTime? memberSince,
    bool? isAdmin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      upiId: upiId ?? this.upiId,
      photoUrl: photoUrl ?? this.photoUrl,
      totalQuizPlayed: totalQuizPlayed ?? this.totalQuizPlayed,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      totalIncorrectAnswers: totalIncorrectAnswers ?? this.totalIncorrectAnswers,
      totalPoints: totalPoints ?? this.totalPoints,
      availablePoints: availablePoints ?? this.availablePoints,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      memberSince: memberSince ?? this.memberSince,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
