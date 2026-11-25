import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/audio/audio_manager.dart';
import '../core/localization/app_strings.dart';

class LanguageProvider with ChangeNotifier {
  static const String _prefKey = 'app_selected_language';
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  String get currentLanguageName {
    switch (_currentLanguage) {
      case 'ur':
        return 'اردو (Urdu)';
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'hinglish':
        return 'Hinglish';
      case 'en':
      default:
        return 'English';
    }
  }

  String get currentLanguageBadge {
    switch (_currentLanguage) {
      case 'ur':
        return '🌐 اردو';
      case 'hi':
        return '🌐 हिं';
      case 'hinglish':
        return '🌐 Hin';
      case 'en':
      default:
        return '🌐 EN';
    }
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && (saved == 'en' || saved == 'hi' || saved == 'hinglish' || saved == 'ur')) {
        _currentLanguage = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage == langCode) return;
    _currentLanguage = langCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (_) {}
  }

  String tr(String key) {
    return AppStrings.get(key, _currentLanguage);
  }
}

class LanguageSelectionModal extends StatelessWidget {
  const LanguageSelectionModal({super.key});

  static Future<void> show(BuildContext context) {
    AudioManager().playClick();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const LanguageSelectionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    final languages = [
      {
        'code': 'en',
        'title': 'English',
        'subtitle': 'Default • All quizzes & UI in clear English',
        'badge': 'EN',
        'icon': '🇬🇧',
      },
      {
        'code': 'hi',
        'title': 'हिंदी (Hindi)',
        'subtitle': 'सभी क्विज़ प्रश्न, उत्तर और मेनू शुद्ध हिंदी में',
        'badge': 'हिंदी',
        'icon': '🇮🇳',
      },
      {
        'code': 'ur',
        'title': 'اردو (Urdu)',
        'subtitle': 'تمام کوئز سوالات، جوابات اور مینو خالص اردو میں',
        'badge': 'اردو',
        'icon': '🇵🇰',
      },
      {
        'code': 'hinglish',
        'title': 'Hinglish',
        'subtitle': 'Easy conversational mix of Hindi + English',
        'badge': 'Hinglish',
        'icon': '🇮🇳',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grab handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    languageProvider.tr('select_language'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...languages.map((lang) {
            final isSelected = currentLang == lang['code'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 2 : 1.2,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                onTap: () async {
                  AudioManager().playClick();
                  await context.read<LanguageProvider>().setLanguage(lang['code'] as String);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                leading: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
                  ),
                  child: Text(
                    lang['icon'] as String,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                title: Text(
                  lang['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  lang['subtitle'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isSelected ? const Color(0xFF4338CA) : AppColors.textSecondary,
                  ),
                ),
                trailing: isSelected
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
