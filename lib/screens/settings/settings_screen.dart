import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../admin/admin_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioManager _audio = AudioManager();

  late bool _musicEnabled;
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late double _musicVol;
  late double _sfxVol;

  @override
  void initState() {
    super.initState();
    _musicEnabled = _audio.isMusicEnabled;
    _soundEnabled = _audio.isSoundEnabled;
    _vibrationEnabled = _audio.isVibrationEnabled;
    _musicVol = _audio.musicVolume;
    _sfxVol = _audio.sfxVolume;
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: () {
        AudioManager().playClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF312E81).withOpacity(0.4) : const Color(0xFFEEF2FF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          'Settings & Preferences',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryOf(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          // APPEARANCE & THEME SECTION
          Text(
            'APPEARANCE & THEME',
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildThemeOption(
                  context: context,
                  title: 'Light Mode',
                  subtitle: 'Clean white surfaces with high contrast',
                  icon: Icons.light_mode_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  isSelected: themeProv.themeMode == ThemeMode.light,
                  onTap: () => themeProv.setThemeMode(ThemeMode.light),
                ),
                _buildThemeOption(
                  context: context,
                  title: 'Dark Mode',
                  subtitle: 'Obsidian & graphite dark surfaces',
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF818CF8),
                  iconBg: const Color(0xFF1E1B4B),
                  isSelected: themeProv.themeMode == ThemeMode.dark,
                  onTap: () => themeProv.setThemeMode(ThemeMode.dark),
                ),
                _buildThemeOption(
                  context: context,
                  title: 'System Default',
                  subtitle: 'Automatically matches your device settings',
                  icon: Icons.settings_brightness_rounded,
                  iconColor: const Color(0xFF0D9488),
                  iconBg: const Color(0xFFCCFBF1),
                  isSelected: themeProv.themeMode == ThemeMode.system,
                  onTap: () => themeProv.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Audio & Haptic Section
          Text(
            'AUDIO & HAPTICS',
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Background Music Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.music_note_rounded, color: AppColors.secondary, size: 20),
                  ),
                  title: Text('Background Music', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: Text('Looping ambient gaming soundtrack', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                  value: _musicEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    setState(() => _musicEnabled = val);
                    await _audio.setMusicEnabled(val);
                  },
                ),
                if (_musicEnabled) ...[
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, size: 18, color: AppColors.textSecondary),
                      Expanded(
                        child: Slider(
                          value: _musicVol,
                          min: 0.0,
                          max: 1.0,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.cardBorder,
                          onChanged: (v) {
                            setState(() => _musicVol = v);
                            _audio.setMusicVolume(v);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ],
                const Divider(height: 24),

                // Sound Effects Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFCFFAFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: AppColors.accent, size: 20),
                  ),
                  title: Text('Sound Effects (SFX)', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: Text('Timer ticks, correct/wrong chimes', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                  value: _soundEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    setState(() => _soundEnabled = val);
                    await _audio.setSoundEnabled(val);
                  },
                ),
                if (_soundEnabled) ...[
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, size: 18, color: AppColors.textSecondary),
                      Expanded(
                        child: Slider(
                          value: _sfxVol,
                          min: 0.0,
                          max: 1.0,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.cardBorder,
                          onChanged: (v) {
                            setState(() => _sfxVol = v);
                            _audio.setSfxVolume(v);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ],
                const Divider(height: 24),

                // Vibration / Haptics Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEDD5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.vibration_rounded, color: AppColors.warning, size: 20),
                  ),
                  title: Text('Vibrate on Answer', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: Text('Tactile haptic feedback for answers', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                  value: _vibrationEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    setState(() => _vibrationEnabled = val);
                    await _audio.setVibrationEnabled(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Administrator Section (Only visible for authorized admin users)
          if (context.watch<AuthProvider>().currentUser?.isAdmin == true) ...[
            const SizedBox(height: 24),
            Text(
              'ADMINISTRATION',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorderOf(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.goldDark, size: 22),
                ),
                title: Text('Admin Control Dashboard', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: Text('Manage questions, payouts & users', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryOf(context), fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () {
                  AudioManager().playClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
