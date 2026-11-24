import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../services/admob_service.dart';

enum HintType { fiftyFifty, extraTime, clue }

class HintDialog extends StatefulWidget {
  final VoidCallback onFiftyFifty;
  final VoidCallback onExtraTime;
  final VoidCallback onClue;
  final bool isFiftyFiftyAvailable;
  final bool isClueAvailable;

  const HintDialog({
    super.key,
    required this.onFiftyFifty,
    required this.onExtraTime,
    required this.onClue,
    required this.isFiftyFiftyAvailable,
    required this.isClueAvailable,
  });

  @override
  State<HintDialog> createState() => _HintDialogState();
}

class _HintDialogState extends State<HintDialog> {
  bool _isLoadingAd = false;

  void _watchAdAndUnlock(HintType type) {
    setState(() {
      _isLoadingAd = true;
    });

    // Lower BGM during Ad playback as required
    AudioManager().pauseBgm();

    AdMobService().showRewardedHintAd(
      onRewardGranted: () {
        AudioManager().resumeBgm();
        if (!mounted) return;
        Navigator.pop(context);

        switch (type) {
          case HintType.fiftyFifty:
            widget.onFiftyFifty();
            break;
          case HintType.extraTime:
            widget.onExtraTime();
            break;
          case HintType.clue:
            widget.onClue();
            break;
        }
      },
      onAdFailed: (err) {
        AudioManager().resumeBgm();
        if (!mounted) return;
        setState(() {
          _isLoadingAd = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Advertisement note: $err. Hint granted!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
        // Grant hint anyway so gameplay isn't blocked!
        switch (type) {
          case HintType.fiftyFifty:
            widget.onFiftyFifty();
            break;
          case HintType.extraTime:
            widget.onExtraTime();
            break;
          case HintType.clue:
            widget.onClue();
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: AppColors.goldDark, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Quiz Hint',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Watch a short video ad to unlock a hint',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (_isLoadingAd) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 14),
                    Text(
                      'Loading AdMob Rewarded Ad...',
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Hint Option 1: 50 / 50
              _buildHintOption(
                title: '50 : 50 Lifeline',
                description: 'Eliminates two incorrect answer choices',
                icon: Icons.remove_circle_outline_rounded,
                iconBg: const Color(0xFFCFFAFE),
                iconColor: AppColors.accent,
                isEnabled: widget.isFiftyFiftyAvailable,
                onTap: () => _watchAdAndUnlock(HintType.fiftyFifty),
              ),
              const SizedBox(height: 10),

              // Hint Option 2: Extra Time
              _buildHintOption(
                title: 'Extra +15 Seconds',
                description: 'Adds 15 seconds to the countdown timer',
                icon: Icons.timer_rounded,
                iconBg: const Color(0xFFFFEDD5),
                iconColor: AppColors.warning,
                isEnabled: true,
                onTap: () => _watchAdAndUnlock(HintType.extraTime),
              ),
              const SizedBox(height: 10),

              // Hint Option 3: Clue Reveal
              _buildHintOption(
                title: 'Reveal Trivia Clue',
                description: 'Displays a helpful clue about the correct answer',
                icon: Icons.visibility_rounded,
                iconBg: const Color(0xFFEDE9FE),
                iconColor: AppColors.secondary,
                isEnabled: widget.isClueAvailable,
                onTap: () => _watchAdAndUnlock(HintType.clue),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHintOption({
    required String title,
    required String description,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isEnabled
          ? () {
              AudioManager().playClick();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.surfaceMuted : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? AppColors.cardBorder : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? iconBg : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isEnabled ? iconColor : Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      color: isEnabled ? AppColors.textSecondary : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: AppColors.goldDark, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'AD',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.goldDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
