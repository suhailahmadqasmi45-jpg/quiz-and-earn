import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy for Quiz & Earn',
                style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Last Updated: November 2026\n\n'
                '1. Data We Collect:\n'
                'Quiz & Earn values your privacy. We collect minimal information strictly necessary to run your trivia gaming experience:\n'
                '• Full Name (retrieved from Google Sign-In or provided by you)\n'
                '• Email Address (for identification and account recovery)\n'
                '• Mobile Number (for account authentication and customer communication)\n'
                '• UPI ID (exclusively for dispatching earned trivia rewards)\n\n'
                'We NEVER ask for sensitive financial credentials such as bank account numbers, passwords, PINs, Aadhaar, PAN card, or OTPs.\n\n'
                '2. Data Usage:\n'
                'Your data is securely stored and used only to track quiz scores, leaderboards, and credit points. We do not sell or lease personal data to third parties.\n\n'
                '3. Advertisements & Google AdMob:\n'
                'We use Google AdMob to display rewarded video ads and non-intrusive transition interstitial ads. AdMob may process non-personalized device identifiers.\n\n'
                '4. Account Deletion:\n'
                'You have the complete right to delete your profile and associated records anytime from the profile settings.',
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Conditions of Service',
                style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Eligibility:\n'
                'Quiz & Earn is a skill-based trivia and general knowledge game. Participation is open to users testing knowledge in science, general knowledge, mathematics, sports, and visual puzzles.\n\n'
                '2. In-App Points & Rewards:\n'
                'Points earned in the app reflect trivia test achievement. Points conversion rates (e.g., 1,000 Points = ₹10) are determined by application management.\n\n'
                '3. Fair Play & Security:\n'
                'The use of automated bots, scripts, or malicious emulators is strictly prohibited and results in immediate account suspension.\n\n'
                '4. Modifications:\n'
                'Quiz & Earn reserves the right to adjust question banks and reward configurations to preserve gaming balance.',
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 12),
                Text('We Are Here To Help', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Support Email: support@quizandearn.com\nOperating Hours: 24/7 Dedicated Support',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          _buildFaq(
            'How do I earn points in Quiz & Earn?',
            'Points are awarded for answering trivia questions correctly within the allotted timer. More difficult questions award higher points up to 50 pts per question.',
          ),
          _buildFaq(
            'How does the 3D ATM Card work?',
            'Your digital card tracks your gaming achievements, total points, and virtual balance. Simply tap the card in the Wallet section to flip it and view your player credentials.',
          ),
          _buildFaq(
            'How do I unlock hints during a quiz?',
            'Tap the Hint button on the top right of the quiz screen and choose 50:50, extra time, or a clue by watching a short video ad.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaq(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ExpansionTile(
        title: Text(question, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(answer, style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 12, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class RewardPolicyScreen extends StatelessWidget {
  const RewardPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Reward Policy',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz & Earn Reward & Payout Policy',
                style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Points & Valuation:\n'
                '• Players earn points by correctly answering trivia questions.\n'
                '• Standard redemption rate: 100 points = ₹1.00 INR.\n\n'
                '2. Payout Methods:\n'
                '• Payouts are dispatched directly to the valid Indian UPI VPA registered on your profile.\n'
                '• Minimum redemption threshold: ₹50.00 (5,000 points).\n\n'
                '3. Verification & Eligibility:\n'
                '• Adding a UPI ID does not guarantee payout eligibility.\n'
                '• High-value redemptions may undergo anti-fraud score review.\n'
                '• Automated bots, scripts, or multiple accounts are strictly disqualified under our Fair Play rules.\n\n'
                '4. Processing Timeline:\n'
                '• Standard UPI payouts are processed within 24 to 48 business hours.',
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildNotificationItem(
            'Welcome Bonus Credited!',
            '100 Welcome Points have been credited to your Platinum digital ATM card.',
            'Just now',
            Icons.card_giftcard_rounded,
            const Color(0xFFFEF3C7),
            AppColors.goldDark,
          ),
          _buildNotificationItem(
            'New Science Questions Added',
            'Explore 100 new Physics, Space, and Artificial Intelligence trivia challenges.',
            '2 hours ago',
            Icons.science_rounded,
            const Color(0xFFCFFAFE),
            AppColors.accent,
          ),
          _buildNotificationItem(
            'Daily Streak Reminder',
            'Play today\'s trivia round to maintain your streak bonus!',
            'Yesterday',
            Icons.bolt_rounded,
            const Color(0xFFFFEDD5),
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String desc, String time, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
                Text(title, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 6),
                Text(time, style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
