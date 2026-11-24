class QuestionModel {
  final String id;
  final String categoryId;
  final String questionText;
  final String? questionTextHi;
  final String? questionTextHinglish;
  final String? imageUrl;
  final List<String> options;
  final List<String>? optionsHi;
  final List<String>? optionsHinglish;
  final int correctOptionIndex;
  final int difficultyLevel;
  final String difficultyTitle;
  final int timerDuration;
  final int pointsReward;
  final String explanation;
  final String? explanationHi;
  final String? explanationHinglish;
  final String hintText;
  final String? hintTextHi;
  final String? hintTextHinglish;
  final bool isPublished;

  QuestionModel({
    required this.id,
    required this.categoryId,
    required this.questionText,
    this.questionTextHi,
    this.questionTextHinglish,
    this.imageUrl,
    required this.options,
    this.optionsHi,
    this.optionsHinglish,
    required this.correctOptionIndex,
    required this.difficultyLevel,
    required this.difficultyTitle,
    required this.timerDuration,
    required this.pointsReward,
    required this.explanation,
    this.explanationHi,
    this.explanationHinglish,
    required this.hintText,
    this.hintTextHi,
    this.hintTextHinglish,
    this.isPublished = true,
  });

  String getLocalizedQuestion(String lang) {
    if (lang == 'hi' && questionTextHi != null && questionTextHi!.isNotEmpty) {
      return questionTextHi!;
    }
    if (lang == 'hinglish' && questionTextHinglish != null && questionTextHinglish!.isNotEmpty) {
      return questionTextHinglish!;
    }
    return questionText;
  }

  List<String> getLocalizedOptions(String lang) {
    if (lang == 'hi' && optionsHi != null && optionsHi!.length == options.length) {
      return optionsHi!;
    }
    if (lang == 'hinglish' && optionsHinglish != null && optionsHinglish!.length == options.length) {
      return optionsHinglish!;
    }
    return options;
  }

  String getLocalizedHint(String lang) {
    if (lang == 'hi' && hintTextHi != null && hintTextHi!.isNotEmpty) {
      return hintTextHi!;
    }
    if (lang == 'hinglish' && hintTextHinglish != null && hintTextHinglish!.isNotEmpty) {
      return hintTextHinglish!;
    }
    return hintText;
  }

  String getLocalizedExplanation(String lang) {
    if (lang == 'hi' && explanationHi != null && explanationHi!.isNotEmpty) {
      return explanationHi!;
    }
    if (lang == 'hinglish' && explanationHinglish != null && explanationHinglish!.isNotEmpty) {
      return explanationHinglish!;
    }
    return explanation;
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      questionText: json['questionText'] as String,
      questionTextHi: json['questionTextHi'] as String?,
      questionTextHinglish: json['questionTextHinglish'] as String?,
      imageUrl: json['imageUrl'] as String?,
      options: List<String>.from(json['options'] as List),
      optionsHi: json['optionsHi'] != null ? List<String>.from(json['optionsHi'] as List) : null,
      optionsHinglish: json['optionsHinglish'] != null ? List<String>.from(json['optionsHinglish'] as List) : null,
      correctOptionIndex: json['correctOptionIndex'] as int,
      difficultyLevel: json['difficultyLevel'] as int? ?? 1,
      difficultyTitle: json['difficultyTitle'] as String? ?? 'Easy',
      timerDuration: json['timerDuration'] as int? ?? 30,
      pointsReward: json['pointsReward'] as int? ?? 5,
      explanation: json['explanation'] as String? ?? '',
      explanationHi: json['explanationHi'] as String?,
      explanationHinglish: json['explanationHinglish'] as String?,
      hintText: json['hintText'] as String? ?? '',
      hintTextHi: json['hintTextHi'] as String?,
      hintTextHinglish: json['hintTextHinglish'] as String?,
      isPublished: json['isPublished'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'questionText': questionText,
      if (questionTextHi != null) 'questionTextHi': questionTextHi,
      if (questionTextHinglish != null) 'questionTextHinglish': questionTextHinglish,
      'imageUrl': imageUrl,
      'options': options,
      if (optionsHi != null) 'optionsHi': optionsHi,
      if (optionsHinglish != null) 'optionsHinglish': optionsHinglish,
      'correctOptionIndex': correctOptionIndex,
      'difficultyLevel': difficultyLevel,
      'difficultyTitle': difficultyTitle,
      'timerDuration': timerDuration,
      'pointsReward': pointsReward,
      'explanation': explanation,
      if (explanationHi != null) 'explanationHi': explanationHi,
      if (explanationHinglish != null) 'explanationHinglish': explanationHinglish,
      'hintText': hintText,
      if (hintTextHi != null) 'hintTextHi': hintTextHi,
      if (hintTextHinglish != null) 'hintTextHinglish': hintTextHinglish,
      'isPublished': isPublished,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? categoryId,
    String? questionText,
    String? imageUrl,
    List<String>? options,
    int? correctOptionIndex,
    int? difficultyLevel,
    String? difficultyTitle,
    int? timerDuration,
    int? pointsReward,
    String? explanation,
    String? hintText,
    bool? isPublished,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      questionText: questionText ?? this.questionText,
      imageUrl: imageUrl ?? this.imageUrl,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      difficultyTitle: difficultyTitle ?? this.difficultyTitle,
      timerDuration: timerDuration ?? this.timerDuration,
      pointsReward: pointsReward ?? this.pointsReward,
      explanation: explanation ?? this.explanation,
      hintText: hintText ?? this.hintText,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}
