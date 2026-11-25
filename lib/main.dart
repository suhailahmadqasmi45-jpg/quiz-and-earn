import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/audio/audio_manager.dart';
import 'repositories/quiz_repository.dart';
import 'services/admob_service.dart';
import 'services/wallet_service.dart';
import 'providers/auth_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safeguard against unhandled framework or platform errors causing abrupt exit
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error caught: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error caught safely: $error');
    return true; // Prevents app crash
  };

  // Lock orientation to portrait for clean gaming experience
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Preferred orientation notice: $e');
  }

  // Status bar and system navigation bar styling
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    debugPrint('System UI overlay notice: $e');
  }

  // Initialize Firebase safely (gracefully supports offline/local mode if config isn't placed yet)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize core services safely with error isolation
  try {
    final audioManager = AudioManager();
    await audioManager.init();
  } catch (e) {
    debugPrint('AudioManager initialization notice: $e');
  }

  try {
    final quizRepo = QuizRepository();
    await quizRepo.init();
  } catch (e) {
    debugPrint('QuizRepository initialization notice: $e');
  }

  try {
    final walletService = WalletService();
    await walletService.init();
  } catch (e) {
    debugPrint('WalletService initialization notice: $e');
  }

  try {
    final admobService = AdMobService();
    await admobService.init();
  } catch (e) {
    debugPrint('AdMobService initialization notice: $e');
  }

  runApp(const QuizAndEarnApp());
}

class QuizAndEarnApp extends StatelessWidget {
  const QuizAndEarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()..init()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Quiz & Earn',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (_) => const SplashScreen(),
              '/admin': (_) => const AdminDashboardScreen(),
              '/admin-login': (_) => const AdminLoginScreen(),
            },
          );
        },
      ),
    );
  }
}
