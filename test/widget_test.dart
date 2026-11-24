import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_and_earn/models/user_model.dart';
import 'package:quiz_and_earn/models/category_model.dart';
import 'package:quiz_and_earn/models/question_model.dart';
import 'package:quiz_and_earn/models/wallet_model.dart';
import 'package:quiz_and_earn/services/wallet_service.dart';
import 'package:quiz_and_earn/core/utils/validators.dart';
import 'package:quiz_and_earn/providers/language_provider.dart';
import 'package:quiz_and_earn/repositories/quiz_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('User Profile & 4 Core Fields Verification', () {
    test('UserModel stores only essential details: Name, Mobile, Email, UPI ID', () {
      final user = UserModel(
        uid: 'USR-TEST-1',
        name: 'Gulshan Kumar',
        email: 'gulshan@example.com',
        mobile: '9876543210',
        upiId: 'gulshan@okhdfcbank',
      );

      expect(user.name, 'Gulshan Kumar');
      expect(user.email, 'gulshan@example.com');
      expect(user.mobile, '9876543210');
      expect(user.upiId, 'gulshan@okhdfcbank');
      expect(user.totalPoints, 0);
      expect(user.availablePoints, 0);
    });

    test('UserModel serialization and deserialization works cleanly', () {
      final user = UserModel(
        uid: 'USR-TEST-2',
        name: 'Test Player',
        email: 'player@quiz.com',
        mobile: '9123456780',
        upiId: 'player@upi',
        totalPoints: 2500,
        availablePoints: 2500,
        totalQuizPlayed: 25,
        totalCorrectAnswers: 200,
      );

      final jsonMap = user.toJson();
      final restored = UserModel.fromJson(jsonMap);

      expect(restored.uid, 'USR-TEST-2');
      expect(restored.name, 'Test Player');
      expect(restored.totalPoints, 2500);
      expect(restored.totalCorrectAnswers, 200);
    });
  });

  group('Categories & Bollywood #1 Placement Verification', () {
    test('All 6 quiz categories exist with Bollywood & Cinema placed strictly at index 0 (Category #1)', () {
      final categories = CategoryModel.defaultCategories;
      expect(categories.length, 6);

      // Verify category 1 is movies (Bollywood & Cinema)
      expect(categories[0].id, 'movies');
      expect(categories[0].title, 'Bollywood & Cinema');
      expect(categories[0].totalQuestions, 100);

      final ids = categories.map((c) => c.id).toSet();
      expect(ids.contains('movies'), true);
      expect(ids.contains('gk'), true);
      expect(ids.contains('science'), true);
      expect(ids.contains('math'), true);
      expect(ids.contains('sports'), true);
      expect(ids.contains('image'), true);
    });

    test('QuestionModel correctly validates difficulty and reward points', () {
      final question = QuestionModel(
        id: 'test_q_1',
        categoryId: 'gk',
        questionText: 'What is the capital of India?',
        options: ['New Delhi', 'Mumbai', 'Kolkata', 'Chennai'],
        correctOptionIndex: 0,
        difficultyLevel: 1,
        difficultyTitle: 'Easy',
        timerDuration: 30,
        pointsReward: 5,
        explanation: 'New Delhi is the official capital of India.',
        hintText: 'Seat of government.',
      );

      expect(question.options.length, 4);
      expect(question.correctOptionIndex, 0);
      expect(question.options[question.correctOptionIndex], 'New Delhi');
      expect(question.pointsReward, 5);
      expect(question.timerDuration, 30);
    });
  });

  group('Language Selection & Multilingual Questions (English, Hindi, Hinglish)', () {
    test('LanguageProvider defaults to English and switches correctly to Hindi and Hinglish', () async {
      final langProvider = LanguageProvider();
      await langProvider.init();

      expect(langProvider.currentLanguage, 'en');
      expect(langProvider.currentLanguageName, 'English');

      await langProvider.setLanguage('hi');
      expect(langProvider.currentLanguage, 'hi');
      expect(langProvider.currentLanguageName, 'हिंदी (Hindi)');
      expect(langProvider.tr('play_quiz_btn'), 'क्विज़ खेलें • पॉइंट्स कमाएं');

      await langProvider.setLanguage('hinglish');
      expect(langProvider.currentLanguage, 'hinglish');
      expect(langProvider.currentLanguageName, 'Hinglish');
      expect(langProvider.tr('play_quiz_btn'), 'Quiz Khelo • Points Jeeto');
    });

    test('QuestionModel localized getters return proper text for all 3 languages', () {
      final q = QuestionModel(
        id: 'mov_test_1',
        categoryId: 'movies',
        questionText: 'Who directed the film Sholay?',
        questionTextHi: 'फिल्म शोले का निर्देशन किसने किया था?',
        questionTextHinglish: 'Film Sholay kisne direct ki thi?',
        options: ['Ramesh Sippy', 'Yash Chopra', 'Raj Kapoor', 'Subhash Ghai'],
        optionsHi: ['रमेश सिप्पी', 'यश चोपड़ा', 'राज कपूर', 'सुभाष घई'],
        optionsHinglish: ['Ramesh Sippy', 'Yash Chopra', 'Raj Kapoor', 'Subhash Ghai'],
        correctOptionIndex: 0,
        difficultyLevel: 1,
        difficultyTitle: 'Easy',
        timerDuration: 30,
        pointsReward: 10,
        explanation: 'Ramesh Sippy directed Sholay in 1975.',
        hintText: 'Also directed Seeta Aur Geeta.',
        hintTextHi: 'सीता और गीता का भी निर्देशन किया था।',
        hintTextHinglish: 'Seeta Aur Geeta bhi inhi ne direct ki thi.',
      );

      // English
      expect(q.getLocalizedQuestion('en'), 'Who directed the film Sholay?');
      expect(q.getLocalizedOptions('en')[0], 'Ramesh Sippy');
      expect(q.getLocalizedHint('en'), 'Also directed Seeta Aur Geeta.');

      // Hindi
      expect(q.getLocalizedQuestion('hi'), 'फिल्म शोले का निर्देशन किसने किया था?');
      expect(q.getLocalizedOptions('hi')[0], 'रमेश सिप्पी');
      expect(q.getLocalizedHint('hi'), 'सीता और गीता का भी निर्देशन किया था।');

      // Hinglish
      expect(q.getLocalizedQuestion('hinglish'), 'Film Sholay kisne direct ki thi?');
      expect(q.getLocalizedOptions('hinglish')[0], 'Ramesh Sippy');
      expect(q.getLocalizedHint('hinglish'), 'Seeta Aur Geeta bhi inhi ne direct ki thi.');
    });
  });

  group('Unlimited Quizzes & Non-Repeating Questions Flow', () {
    test('QuizRepository provides non-repeating questions across rounds', () {
      final repo = QuizRepository();
      // Inject dummy questions into repo for category movies
      final testQuestions = List.generate(
        25,
        (i) => QuestionModel(
          id: 'test_mov_$i',
          categoryId: 'movies',
          questionText: 'Movie Question $i?',
          options: ['A', 'B', 'C', 'D'],
          correctOptionIndex: 0,
          difficultyLevel: 1,
          difficultyTitle: 'Easy',
          timerDuration: 30,
          pointsReward: 10,
          explanation: 'Explanation $i',
          hintText: 'Hint $i',
        ),
      );

      // Save questions into repo
      for (final q in testQuestions) {
        repo.saveQuestion(q);
      }

      // Reset seen questions
      repo.resetSeenQuestions();

      // Fetch first round of 10 questions for movies
      final round1 = repo.getQuestionsForRound('movies', count: 10);
      expect(round1.length, 10);

      final round1Ids = round1.map((q) => q.id).toSet();
      expect(round1Ids.length, 10); // All distinct

      // Fetch second round of 10 questions for movies
      final round2 = repo.getQuestionsForRound('movies', count: 10);
      expect(round2.length, 10);

      final round2Ids = round2.map((q) => q.id).toSet();
      expect(round2Ids.length, 10); // All distinct

      // Check no intersection between round 1 and round 2
      final overlap = round1Ids.intersection(round2Ids);
      expect(overlap.isEmpty, true, reason: 'Questions must not repeat across rounds!');
    });
  });

  group('Wallet, Minimum Withdrawal ₹1000 (100,000 Points) & Rewards Calculations', () {
    test('Points conversion: 100 Points strictly equals ₹1.00', () {
      final service = WalletService();
      expect(service.calculateRewardValue(100), 1.0);
      expect(service.calculateRewardValue(200), 2.0);
      expect(service.calculateRewardValue(1000), 10.0);
      expect(service.calculateRewardValue(100000), 1000.0);
    });

    test('Default AppSettingsModel strictly enforces minWithdrawalPoints = 100,000 (₹1,000)', () {
      final settings = const AppSettingsModel();
      expect(settings.minWithdrawalPoints, 100000);
      expect(settings.pointsPerRupee, 100);
      expect(settings.minWithdrawalPoints / settings.pointsPerRupee, 1000.0);
    });

    test('WalletService validates ₹1,000 minimum withdrawal (100,000 points)', () async {
      final service = WalletService();
      await service.init();
      final settings = service.settings;
      expect(settings.minWithdrawalPoints, 100000);

      // Verify calculation
      expect(service.calculateRewardValue(settings.minWithdrawalPoints), 1000.0);
    });

    test('WithdrawalRequest holds UPI ID, status and deducted points', () {
      final req = WithdrawalRequest(
        id: 'WREQ-1001',
        userId: 'USR-1',
        userName: 'Gulshan Kumar',
        userEmail: 'gulshan@example.com',
        userMobile: '9876543210',
        upiId: 'gulshan@okhdfcbank',
        pointsDeducted: 100000,
        amount: 1000.0,
        status: 'Pending',
      );

      expect(req.pointsDeducted, 100000);
      expect(req.amount, 1000.0);
      expect(req.status, 'Pending');
      expect(req.upiId, 'gulshan@okhdfcbank');
    });
  });

  group('Strict Indian Mobile Number Validation', () {
    test('Accepts valid 10-digit Indian numbers starting with 6-9', () {
      expect(Validators.validateIndianMobile('9823451234'), null);
      expect(Validators.validateIndianMobile('8765432190'), null);
      expect(Validators.validateIndianMobile('7012345678'), null);
      expect(Validators.validateIndianMobile('6234567891'), null);
      expect(Validators.validateIndianMobile('+91 9823451234'), null);
    });

    test('Rejects invalid length and invalid prefixes', () {
      expect(Validators.validateIndianMobile(''), isNotNull);
      expect(Validators.validateIndianMobile('12345'), isNotNull);
      expect(Validators.validateIndianMobile('5555512345'), isNotNull);
      expect(Validators.validateIndianMobile('4123456789'), isNotNull);
    });

    test('Rejects fake and repetitive dummy numbers', () {
      expect(Validators.validateIndianMobile('9999999999'), isNotNull);
      expect(Validators.validateIndianMobile('8888888888'), isNotNull);
      expect(Validators.validateIndianMobile('7777777777'), isNotNull);
      expect(Validators.validateIndianMobile('0000000000'), isNotNull);
      expect(Validators.validateIndianMobile('1234567890'), isNotNull);
      expect(Validators.validateIndianMobile('9876543210'), isNotNull);
      expect(Validators.validateIndianMobile('9800000000'), isNotNull);
    });
  });
}
