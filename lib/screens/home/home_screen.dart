import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/category_model.dart';
import '../quiz/quiz_gameplay_screen.dart';
import '../legal/legal_screens.dart';
import '../profile/edit_profile_screen.dart';
import '../../services/admob_service.dart';
import '../../widgets/native_ad_card.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _hasShownSessionReminder = false;
  bool _bannerDismissed = false;
  bool _dailyBonusClaimed = false;
  String _bonusCountdownText = '';
  bool _isClaimingBonus = false;

  @override
  void initState() {
    super.initState();
    _checkDailyBonusStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpiReminder();
      if (mounted) {
        context.read<WalletProvider>().refreshFromCloud();
      }
    });
  }

  Future<void> _checkDailyBonusStatus() async {
    try {
      final user = context.read<AuthProvider>().currentUser;
      final uid = user?.uid ?? 'default';
      final prefs = await SharedPreferences.getInstance();
      final lastClaim = prefs.getInt('daily_bonus_claim_$uid') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const cooldownMs = 24 * 60 * 60 * 1000;

      if (now - lastClaim < cooldownMs) {
        final remainingMs = cooldownMs - (now - lastClaim);
        final hours = remainingMs ~/ (1000 * 60 * 60);
        final minutes = (remainingMs % (1000 * 60 * 60)) ~/ (1000 * 60);
        if (mounted) {
          setState(() {
            _dailyBonusClaimed = true;
            _bonusCountdownText = 'Next bonus in ${hours}h ${minutes}m';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _dailyBonusClaimed = false;
            _bonusCountdownText = '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _claimDailyBonus() async {
    if (_dailyBonusClaimed || _isClaimingBonus) return;

    setState(() => _isClaimingBonus = true);
    AudioManager().playCorrect();

    try {
      final wallet = context.read<WalletProvider>();
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      final uid = user?.uid ?? 'default';

      // 1. Add +50 points and log transaction in wallet
      await wallet.claimDailyBonus(50);
      auth.refresh();

      // 2. Persist claim timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_bonus_claim_$uid', DateTime.now().millisecondsSinceEpoch);

      if (mounted) {
        setState(() {
          _dailyBonusClaimed = true;
          _bonusCountdownText = 'Next bonus in 24h';
          _isClaimingBonus = false;
        });

        // 3. Show celebration feedback dialog
        _showDailyBonusCelebrationDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClaimingBonus = false);
      }
    }
  }

  void _showDailyBonusCelebrationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 18),
            Text(
              'Daily Bonus Claimed!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You received +50 Points in your digital wallet! Come back tomorrow for your next reward.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Awesome!',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkUpiReminder() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.upiId.isEmpty && !_hasShownSessionReminder) {
      _hasShownSessionReminder = true;
      _showUpiModalReminder();
    }
  }

  void _showUpiModalReminder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x2A000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Your Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please add your UPI ID in your profile to complete your wallet details and prepare for future reward redemptions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  'Note: Saving a UPI ID does not verify bank ownership or guarantee payout eligibility.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(focusUpiField: true),
                      ),
                    );
                  },
                  child: Text(
                    'Update UPI ID',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Remind Me Later',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeGreeting(LanguageProvider lang) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return lang.tr('greeting_morning');
    } else if (hour < 17) {
      return lang.tr('greeting_afternoon');
    } else {
      return lang.tr('greeting_evening');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final wallet = context.watch<WalletProvider>();
    final lang = context.watch<LanguageProvider>();
    final categories = CategoryModel.defaultCategories;
    final userName = user?.name ?? 'Player';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Avatar, Greeting, Points Pill, Notifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AudioManager().playClick();
                        widget.onNavigateTab(3); // Jump to Profile
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFEEF2FF),
                              backgroundImage: user?.photoUrl != null
                                  ? NetworkImage(user!.photoUrl!)
                                  : null,
                              child: user?.photoUrl == null
                                  ? const Icon(Icons.person, color: AppColors.primary, size: 24)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTimeGreeting(lang),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Points Pill & Notifications
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          AudioManager().playClick();
                          widget.onNavigateTab(2); // Jump to Wallet
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: AppColors.goldDark, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${wallet.availablePoints} Pts',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.goldDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBgOf(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorderOf(context)),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.notifications_outlined, color: AppColors.textPrimaryOf(context), size: 20),
                          onPressed: () {
                            AudioManager().playClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // UPI ID Completion Banner (if UPI is missing)
              if (user != null && user.upiId.isEmpty && !_bannerDismissed) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1D4ED8), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Complete Your Profile',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1E3A8A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _bannerDismissed = true;
                              });
                            },
                            child: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please add your UPI ID in your profile to complete your wallet details and prepare for future reward redemptions.',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1E40AF),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(focusUpiField: true),
                                ),
                              );
                            },
                            child: Text(
                              'Update UPI ID',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _bannerDismissed = true;
                              });
                            },
                            child: Text(
                              'Remind Me Later',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF4B5563),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // 2. Mini ATM Digital Wallet Preview Card
              InkWell(
                onTap: () {
                  AudioManager().playClick();
                  widget.onNavigateTab(2); // Jump to Wallet Tab
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.atmCardGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E1B4B).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.credit_card_rounded, color: AppColors.gold, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'DIGITAL REWARD CARD',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'VIEW WALLET',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textOnDarkMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '₹${wallet.availableBalance.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Points',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textOnDarkMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: AppColors.gold, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${wallet.availablePoints} Points',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.gold,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. High-Impact Featured Quiz Card
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  AudioManager().playClick();
                  AdMobService().showInterstitialAd(
                    onClosed: () {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizGameplayScreen(
                            category: categories.first,
                            startLevel: 1,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 175,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // Background Photo
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/featured_quiz.webp',
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Dark Gradient Overlay for high-contrast readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.30),
                                  Colors.black.withOpacity(0.85),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Tag Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE11D48).withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE11D48).withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 11)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'DAILY FEATURED CHALLENGE',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.stars_rounded, color: AppColors.gold, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+500 Pts',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppColors.gold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Title & Subtitle + Play Button Row
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bollywood & Cinema Super Quiz',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.6),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Test your movie knowledge & earn reward points',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withOpacity(0.88),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.play_arrow_rounded, color: Color(0xFF0F172A), size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Play Now',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: const Color(0xFF0F172A),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '10 Questions • 30s per Q',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white.withOpacity(0.75),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Native Advanced Ad Banner
              const NativeAdCard(
                margin: EdgeInsets.only(bottom: 20),
              ),

              // 4. Categories Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.tr('quiz_categories'),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      AudioManager().playClick();
                      widget.onNavigateTab(1); // Jump to Categories tab
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${lang.tr('view_all')} (${categories.length})',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Horizontal Category List Cards with Real Photography
              SizedBox(
                height: 205,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    return Container(
                      width: 175,
                      margin: const EdgeInsets.only(right: 14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          AudioManager().playClick();
                          AdMobService().showInterstitialAd(
                            onClosed: () {
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizGameplayScreen(
                                    category: cat,
                                    startLevel: 1,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardBgOf(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorderOf(context), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Real Photography Banner with Gradient
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                                child: Stack(
                                  children: [
                                    Image.asset(
                                      cat.bannerAsset,
                                      height: 98,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      height: 98,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.4),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.92),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.12),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Icon(cat.icon, color: cat.primaryColor, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textPrimaryOf(context),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      cat.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textSecondaryOf(context),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${cat.totalQuestions} Qs',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 26),

              // 5. Total Performance Stats
              Text(
                lang.tr('career_statistics'),
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildCareerStat(
                      title: lang.tr('quizzes_played'),
                      value: '${user?.totalQuizPlayed ?? 0}',
                      icon: Icons.sports_esports_rounded,
                      iconBg: const Color(0xFFEDE9FE),
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCareerStat(
                      title: lang.tr('correct_answers'),
                      value: '${user?.totalCorrectAnswers ?? 0}',
                      icon: Icons.check_circle_rounded,
                      iconBg: const Color(0xFFD1FAE5),
                      color: AppColors.correct,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCareerStat(
                      title: lang.tr('total_earnings'),
                      value: '₹${wallet.totalEarningsValue.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee_rounded,
                      iconBg: const Color(0xFFFEF3C7),
                      color: AppColors.goldDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 6. Interactive Daily Bonus Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _dailyBonusClaimed
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _dailyBonusClaimed ? const Color(0xFFF8FAFC) : null,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _dailyBonusClaimed ? AppColors.cardBorder : const Color(0xFFFDE68A),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _dailyBonusClaimed
                          ? const Color(0xFF0F172A).withOpacity(0.02)
                          : const Color(0xFFF59E0B).withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: _dailyBonusClaimed ? null : AppColors.goldGradient,
                        color: _dailyBonusClaimed ? const Color(0xFFE2E8F0) : null,
                        shape: BoxShape.circle,
                        boxShadow: _dailyBonusClaimed
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Icon(
                        _dailyBonusClaimed ? Icons.check_rounded : Icons.card_giftcard_rounded,
                        color: _dailyBonusClaimed ? AppColors.textSecondary : Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _dailyBonusClaimed ? lang.tr('daily_bonus_claimed') : lang.tr('daily_bonus_title'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: _dailyBonusClaimed ? AppColors.textPrimary : const Color(0xFF92400E),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (!_dailyBonusClaimed) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+50 PTS',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _dailyBonusClaimed
                                ? (_bonusCountdownText.isNotEmpty
                                    ? _bonusCountdownText
                                    : lang.tr('daily_bonus_claimed_sub'))
                                : lang.tr('daily_bonus_sub'),
                            style: GoogleFonts.plusJakartaSans(
                              color: _dailyBonusClaimed ? AppColors.textSecondary : const Color(0xFFB45309),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dailyBonusClaimed ? const Color(0xFFE2E8F0) : AppColors.primary,
                        foregroundColor: _dailyBonusClaimed ? AppColors.textSecondary : Colors.white,
                        elevation: _dailyBonusClaimed ? 0 : 2,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _dailyBonusClaimed ? null : _claimDailyBonus,
                      child: Text(
                        _dailyBonusClaimed ? lang.tr('claimed_btn') : lang.tr('claim_btn'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _dailyBonusClaimed ? AppColors.textSecondary : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Extra padding to ensure full scrolling above floating liquid nav bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareerStat({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimaryOf(context),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
