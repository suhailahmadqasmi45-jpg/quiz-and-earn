import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/category_model.dart';
import 'hint_dialog.dart';
import 'quiz_result_screen.dart';

class QuizGameplayScreen extends StatefulWidget {
  final CategoryModel category;
  final int startLevel;

  const QuizGameplayScreen({
    super.key,
    required this.category,
    this.startLevel = 1,
  });

  @override
  State<QuizGameplayScreen> createState() => _QuizGameplayScreenState();
}

class _QuizGameplayScreenState extends State<QuizGameplayScreen> {
  @override
  void initState() {
    super.initState();
    AudioManager().playQuizBgm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().startQuizRound(
            widget.category,
            startLevel: widget.startLevel,
            count: 10,
          );
    });
  }

  @override
  void dispose() {
    AudioManager().playHomeBgm();
    super.dispose();
  }

  void _showHintDialog() {
    final quiz = context.read<QuizProvider>();
    if (quiz.isAnswerChecked) return;

    AudioManager().playClick();
    showDialog(
      context: context,
      builder: (_) => HintDialog(
        isFiftyFiftyAvailable: quiz.eliminatedOptions.isEmpty,
        isClueAvailable: !quiz.isClueRevealed,
        onFiftyFifty: () => quiz.apply5050Hint(),
        onExtraTime: () => quiz.applyExtraTimeHint(),
        onClue: () => quiz.applyClueHint(),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final lang = context.read<LanguageProvider>();
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          lang.tr('leave_quiz_title'),
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          lang.tr('leave_quiz_desc'),
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              lang.tr('stay_btn'),
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wrong,
              elevation: 0,
            ),
            child: Text(
              lang.tr('exit_quiz_btn'),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  // Clean raw question prefixes like "GK Question #100: " or similar
  String _formatQuestionText(String raw) {
    return raw.replaceAll(RegExp(r'^[A-Za-z\s]+Question\s*#?\d*:\s*', caseSensitive: false), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final lang = context.watch<LanguageProvider>();
    final q = quiz.currentQuestion;

    if (quiz.isQuizCompleted) {
      return QuizResultScreen(category: widget.category);
    }

    if (q == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final totalDuration = q.timerDuration > 0 ? q.timerDuration : 30;
    final progress = (quiz.remainingSeconds / totalDuration).clamp(0.0, 1.0);
    final isUrgent = quiz.remainingSeconds <= 5;
    final cleanQuestionText = _formatQuestionText(q.getLocalizedQuestion(lang.currentLanguage));
    final localizedOptions = q.getLocalizedOptions(lang.currentLanguage);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.category.primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.category.icon, color: widget.category.primaryColor, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.category.title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Modern Hint Button
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFBEB),
                  foregroundColor: AppColors.goldDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.gold.withOpacity(0.6), width: 1.2),
                  ),
                ),
                icon: const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.goldDark),
                label: Text(
                  lang.tr('hint'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: quiz.isAnswerChecked ? null : _showHintDialog,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Progress & Reward Points Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Question progress pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgOf(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderOf(context)),
                      ),
                      child: Text(
                        '${lang.tr('question')} ${quiz.currentIndex + 1} ${lang.tr('of')} ${quiz.questions.length}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondaryOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Difficulty & Reward Points Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Level ${q.difficultyLevel} (${q.difficultyTitle}) • +${q.pointsReward} Pts',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Countdown Timer Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: isUrgent ? AppColors.wrong : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lang.tr('time_remaining'),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${quiz.remainingSeconds}s',
                            style: GoogleFonts.plusJakartaSans(
                              color: isUrgent ? AppColors.wrong : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.cardBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUrgent ? AppColors.wrong : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Question & Options Scrollable Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Mystery/Quiz Image if available
                      if (q.imageUrl != null) ...[
                        Container(
                          width: double.infinity,
                          height: 190,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: Image.asset(
                              q.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: Icon(Icons.image_rounded, color: Colors.grey, size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Question Card (Pure White with Crisp Typography)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgOf(context),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.cardBorderOf(context), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          cleanQuestionText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Clue banner (if revealed via hint)
                      if (quiz.isClueRevealed) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_rounded, color: AppColors.goldDark, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${lang.tr('hint')}: ${q.getLocalizedHint(lang.currentLanguage)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF92400E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 4 Multiple Choice Option Buttons
                      ...List.generate(localizedOptions.length, (idx) {
                        return _buildOptionButton(
                          optionIndex: idx,
                          optionText: localizedOptions[idx],
                          correctIndex: q.correctOptionIndex,
                          quiz: quiz,
                        );
                      }),

                      // Explanation Card (Reveals after answering)
                      if (quiz.isAnswerChecked) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: quiz.selectedOption == q.correctOptionIndex
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: quiz.selectedOption == q.correctOptionIndex
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    quiz.selectedOption == q.correctOptionIndex
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: quiz.selectedOption == q.correctOptionIndex
                                        ? AppColors.correct
                                        : AppColors.wrong,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    quiz.selectedOption == q.correctOptionIndex
                                        ? 'Correct! (+${q.pointsReward} Points Earned)'
                                        : 'Incorrect Answer',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: quiz.selectedOption == q.correctOptionIndex
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF991B1B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                q.explanation,
                                style: GoogleFonts.plusJakartaSans(
                                  color: quiz.selectedOption == q.correctOptionIndex
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFB91C1C),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 4. Bottom "Next Question" or "View Results" Button
              if (quiz.isAnswerChecked)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        AudioManager().playClick();
                        quiz.nextQuestion();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            quiz.currentIndex + 1 < quiz.questions.length
                                ? lang.tr('next_question')
                                : lang.tr('view_results'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required int optionIndex,
    required String optionText,
    required int correctIndex,
    required QuizProvider quiz,
  }) {
    final isEliminated = quiz.eliminatedOptions.contains(optionIndex);
    final isSelected = (quiz.selectedOption == optionIndex);
    final isCorrect = (optionIndex == correctIndex);
    final letters = ['A', 'B', 'C', 'D'];

    Color bgColor = AppColors.cardBgOf(context);
    Color borderColor = AppColors.cardBorderOf(context);
    Color textColor = AppColors.textPrimaryOf(context);
    Color badgeBg = AppColors.isDark(context) ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    Color badgeText = AppColors.textSecondaryOf(context);
    Widget? trailingIcon;

    if (quiz.isAnswerChecked) {
      if (isCorrect) {
        bgColor = const Color(0xFFECFDF5);
        borderColor = AppColors.correct;
        textColor = const Color(0xFF065F46);
        badgeBg = AppColors.correct;
        badgeText = Colors.white;
        trailingIcon = const Icon(Icons.check_circle_rounded, color: AppColors.correct, size: 22);
      } else if (isSelected) {
        bgColor = const Color(0xFFFEF2F2);
        borderColor = AppColors.wrong;
        textColor = const Color(0xFF991B1B);
        badgeBg = AppColors.wrong;
        badgeText = Colors.white;
        trailingIcon = const Icon(Icons.cancel_rounded, color: AppColors.wrong, size: 22);
      }
    } else if (isSelected) {
      bgColor = const Color(0xFFEEF2FF);
      borderColor = AppColors.primary;
      badgeBg = AppColors.primary;
      badgeText = Colors.white;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isEliminated ? 0.25 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (quiz.isAnswerChecked || isEliminated)
                ? null
                : () {
                    quiz.selectOption(optionIndex);
                  },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || isCorrect ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Option letter indicator (A, B, C, D)
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeBg,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letters[optionIndex % 4],
                      style: GoogleFonts.plusJakartaSans(
                        color: badgeText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      optionText,
                      style: GoogleFonts.plusJakartaSans(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    trailingIcon,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
