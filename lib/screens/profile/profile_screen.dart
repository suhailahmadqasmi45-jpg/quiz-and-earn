import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/language_provider.dart';
import 'edit_profile_screen.dart';
import 'history_screens.dart';
import '../settings/settings_screen.dart';
import '../legal/legal_screens.dart';
import '../auth/login_screen.dart';
import '../admin/admin_login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const ProfileScreen({super.key, this.onNavigateTab});

  Future<void> _pickProfileImage(BuildContext context, ImageSource source) async {
    AudioManager().playClick();
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        await context.read<AuthProvider>().updatePhotoUrl(pickedFile.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: AppColors.correct,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update image: $e'),
            backgroundColor: AppColors.wrong,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet(BuildContext context) {
    AudioManager().playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Profile Photo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
              ),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickProfileImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.correct, size: 22),
              ),
              title: Text(
                'Take Photo with Camera',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickProfileImage(context, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    AudioManager().playClick();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Sign Out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        content: Text('Are you sure you want to log out of Quiz & Earn?', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.wrong, elevation: 0),
            child: Text('Sign Out', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    AudioManager().playClick();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Delete Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.wrong)),
        content: Text(
          'This action is irreversible. All earned points, wallet balance, and quiz progress will be permanently deleted.',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.wrong, elevation: 0),
            child: Text('Delete Permanently', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().deleteAccount();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  ImageProvider? _getAvatarImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }
    return FileImage(File(photoUrl));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final wallet = context.watch<WalletProvider>();
    final lang = context.watch<LanguageProvider>();

    final memberSinceStr = user?.memberSince != null
        ? DateFormat('MMMM yyyy').format(user!.memberSince)
        : 'November 2026';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () {
              AudioManager().playClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Profile Header Card (Avatar + Photo Upload + Member Since)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Tap-To-Upload Camera Pill
                  GestureDetector(
                    onTap: () => _showImagePickerSheet(context),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2.5),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFFEEF2FF),
                            backgroundImage: _getAvatarImage(user?.photoUrl),
                            child: user?.photoUrl == null
                                ? const Icon(Icons.person, color: AppColors.primary, size: 48)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Quiz Champion',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.email.isNotEmpty == true ? user!.email : 'user@example.com',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Member since $memberSinceStr',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. PERSONAL INFORMATION CARD (All 4 details directly visible)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 12,
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
                          const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Personal Information',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          AudioManager().playClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                        child: Text(
                          'Edit',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  const SizedBox(height: 14),

                  // Detail 1: Full Name
                  _buildPersonalDetailRow(
                    icon: Icons.person_rounded,
                    label: 'Full Name',
                    value: user?.name.isNotEmpty == true ? user!.name : 'Not Added',
                  ),
                  const SizedBox(height: 12),

                  // Detail 2: Mobile Number
                  _buildPersonalDetailRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Mobile Number',
                    value: user?.mobile.isNotEmpty == true ? '+91 ${user!.mobile}' : 'Not Added',
                  ),
                  const SizedBox(height: 12),

                  // Detail 3: Email Address
                  _buildPersonalDetailRow(
                    icon: Icons.email_rounded,
                    label: 'Email Address',
                    value: user?.email.isNotEmpty == true ? user!.email : 'Not Added',
                    badge: 'Google Verified',
                  ),
                  const SizedBox(height: 12),

                  // Detail 4: UPI ID
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UPI ID',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.upiId.isNotEmpty == true ? user!.upiId : 'Not Added — Update Now',
                              style: GoogleFonts.plusJakartaSans(
                                color: user?.upiId.isNotEmpty == true
                                    ? AppColors.textPrimary
                                    : const Color(0xFFD97706),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user == null || user.upiId.isEmpty) ...[
                        GestureDetector(
                          onTap: () {
                            AudioManager().playClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(focusUpiField: true),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              'Update',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFB45309),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. USER ACTIVITY SUMMARY (4 Statistics Cards)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Quizzes Played',
                    value: '${user?.totalQuizPlayed ?? 0}',
                    icon: Icons.sports_esports_rounded,
                    iconBg: const Color(0xFFEDE9FE),
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Correct Answers',
                    value: '${user?.totalCorrectAnswers ?? 0}',
                    icon: Icons.check_circle_rounded,
                    iconBg: const Color(0xFFD1FAE5),
                    color: AppColors.correct,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Points Earned',
                    value: '${user?.totalPoints ?? 0}',
                    icon: Icons.stars_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    color: AppColors.goldDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Earnings',
                    value: '₹${wallet.totalEarningsValue.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee_rounded,
                    iconBg: const Color(0xFFCFFAFE),
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Navigation Group 1: Wallet & History
            _buildNavigationGroup([
              _buildNavItem(
                icon: Icons.account_balance_wallet_rounded,
                title: 'My Digital Wallet',
                subtitle: '₹${wallet.availableBalance.toStringAsFixed(2)} available (${wallet.availablePoints} Points)',
                iconBg: const Color(0xFFEEF2FF),
                iconColor: AppColors.primary,
                onTap: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(2);
                  }
                },
              ),
              _buildNavItem(
                icon: Icons.history_edu_rounded,
                title: 'My Quiz History',
                subtitle: '${wallet.quizHistory.length} quiz rounds played',
                iconBg: const Color(0xFFEDE9FE),
                iconColor: AppColors.secondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizHistoryScreen())),
              ),
              _buildNavItem(
                icon: Icons.receipt_long_rounded,
                title: 'Earnings History',
                subtitle: 'Track rewards, bonuses and redemptions',
                iconBg: const Color(0xFFCFFAFE),
                iconColor: AppColors.accent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsHistoryScreen())),
              ),
            ]),
            const SizedBox(height: 16),

            // 5. Navigation Group 2: Settings & Legal
            _buildNavigationGroup([
              _buildNavItem(
                icon: Icons.language_rounded,
                title: 'App Language / भाषा',
                subtitle: '${lang.currentLanguageName} • Tap to switch',
                iconBg: const Color(0xFFEFF6FF),
                iconColor: AppColors.primary,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        lang.currentLanguageName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
                onTap: () => LanguageSelectionModal.show(context),
              ),
              _buildNavItem(
                icon: Icons.edit_note_rounded,
                title: 'Edit Profile',
                subtitle: 'Update name, mobile and UPI ID',
                iconBg: const Color(0xFFEEF2FF),
                iconColor: AppColors.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              ),
              _buildNavItem(
                icon: Icons.tune_rounded,
                title: 'Audio & Settings',
                subtitle: 'Background music, SFX and volume',
                iconBg: const Color(0xFFFFEDD5),
                iconColor: AppColors.warning,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),

              // ROLE-BASED ADMIN PROTECTION:
              // Only shown if user is an authorized administrator! Normal users NEVER see this.
              if (user?.isAdmin == true) ...[
                _buildNavItem(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin Control Panel',
                  subtitle: 'Manage questions, user stats & payouts',
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: AppColors.goldDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
                ),
              ],

              _buildNavItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Data security & AdMob policies',
                iconBg: const Color(0xFFF1F5F9),
                iconColor: AppColors.textSecondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              ),
              _buildNavItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Fair play rules & user guidelines',
                iconBg: const Color(0xFFF1F5F9),
                iconColor: AppColors.textSecondary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
              ),
              _buildNavItem(
                icon: Icons.card_giftcard_rounded,
                title: 'Reward Policy',
                subtitle: 'Points valuation & redemption eligibility',
                iconBg: const Color(0xFFFEF3C7),
                iconColor: AppColors.goldDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardPolicyScreen())),
              ),
              _buildNavItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'FAQs and support email',
                iconBg: const Color(0xFFD1FAE5),
                iconColor: AppColors.correct,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
              ),
            ]),
            const SizedBox(height: 16),

            // Danger Zone Group: Logout & Delete Account
            _buildNavigationGroup([
              _buildNavItem(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'Log out of current session',
                iconBg: const Color(0xFFFEF3C7),
                iconColor: AppColors.goldDark,
                onTap: () => _confirmLogout(context),
              ),
              _buildNavItem(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently remove profile data',
                iconBg: const Color(0xFFFEE2E2),
                iconColor: AppColors.wrong,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ]),
            // Safe bottom padding for floating navigation bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF065F46),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: items,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      onTap: () {
        AudioManager().playClick();
        onTap();
      },
    );
  }
}
