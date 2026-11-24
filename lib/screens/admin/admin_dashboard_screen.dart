import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../models/question_model.dart';
import '../../models/wallet_model.dart';
import 'admin_question_editor_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openQuestionEditor([QuestionModel? q]) {
    AudioManager().playClick();
    showDialog(
      context: context,
      builder: (_) => AdminQuestionEditorDialog(
        existingQuestion: q,
        onSave: (saved) {
          context.read<AdminProvider>().saveQuestion(saved);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(q == null ? 'Question created!' : 'Question updated!'),
              backgroundColor: AppColors.correct,
            ),
          );
        },
      ),
    );
  }

  void _showUserDetailModal(UserModel u, AdminProvider admin) {
    AudioManager().playClick();
    final balance = (u.availablePoints / (admin.settings.pointsPerRupee > 0 ? admin.settings.pointsPerRupee : 100));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('UID: ${u.uid} • Joined: ${DateFormat('yyyy-MM-dd').format(u.memberSince)}',
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildUserDetailRow('Email ID', u.email),
            _buildUserDetailRow('Mobile Number', u.mobile.isNotEmpty ? u.mobile : 'Not provided'),
            _buildUserDetailRow('UPI Address', u.upiId.isNotEmpty ? u.upiId : 'Not provided'),
            _buildUserDetailRow('Quizzes Played', '${u.totalQuizPlayed} rounds'),
            _buildUserDetailRow('Answers Record', '${u.totalCorrectAnswers} Correct / ${u.totalIncorrectAnswers} Incorrect'),
            _buildUserDetailRow('Available Points', '${u.availablePoints} pts'),
            _buildUserDetailRow('Wallet Balance', '₹${balance.toStringAsFixed(2)}'),
            _buildUserDetailRow('Total Withdrawn', '₹${u.totalWithdrawn.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null || !user.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_rounded, color: AppColors.wrong, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Unauthorized Access',
                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'You do not have administrative privileges to view this portal.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Add Question',
            onPressed: () => _openQuestionEditor(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Quizzes'),
            Tab(text: 'Wallet & Ads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(admin),
          _buildUsersTab(admin),
          _buildQuizzesTab(admin),
          _buildWalletAndAdsTab(admin),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM METRICS',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatGrid(admin),
          const SizedBox(height: 22),

          // Quick Action Bar
          Text(
            'MANAGEMENT ACTIONS',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBg,
                    foregroundColor: AppColors.primary,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 18),
                  label: Text('Add Question', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                  onPressed: () => _openQuestionEditor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBg,
                    foregroundColor: AppColors.primary,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.payments_rounded, color: AppColors.primary, size: 18),
                  label: Text('Withdrawals', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                  onPressed: () => _tabController.animateTo(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Pending Withdrawal Requests Snapshot
          Text(
            'PENDING WITHDRAWALS (${admin.pendingWithdrawalsCount})',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          if (admin.withdrawals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No withdrawal requests pending', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
              ),
            )
          else
            ...admin.withdrawals.take(3).map((w) => _buildWithdrawalTile(w, admin)),
        ],
      ),
    );
  }

  Widget _buildStatGrid(AdminProvider admin) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Users', '${admin.totalUsersCount}', Icons.people_rounded, const Color(0xFFCFFAFE), AppColors.accent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Quizzes Played', '${admin.totalQuizzesPlayed}', Icons.sports_esports_rounded, const Color(0xFFEDE9FE), AppColors.secondary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Correct Answers', '${admin.totalCorrectAnswers}', Icons.check_circle_rounded, const Color(0xFFD1FAE5), AppColors.correct)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Points Distributed', '${admin.totalPointsDistributed}', Icons.stars_rounded, const Color(0xFFFEF3C7), AppColors.goldDark)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Reward Value', '₹${admin.totalRewardValue.toStringAsFixed(0)}', Icons.currency_rupee_rounded, const Color(0xFFEEF2FF), AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Pending Requests', '${admin.pendingWithdrawalsCount}', Icons.pending_actions_rounded, const Color(0xFFFFEDD5), AppColors.warning)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color iconBg, Color iconColor) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildUsersTab(AdminProvider admin) {
    final users = admin.users;

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      physics: const BouncingScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, idx) {
        final u = users[idx];
        final balance = (u.availablePoints / (admin.settings.pointsPerRupee > 0 ? admin.settings.pointsPerRupee : 100));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEEF2FF),
              child: Text(u.name.isNotEmpty ? u.name[0] : 'U', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
            title: Text(u.name, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            subtitle: Text('${u.mobile.isNotEmpty ? u.mobile : u.email}\nUPI: ${u.upiId}', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 11)),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${u.totalPoints} pts', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                Text('₹${balance.toStringAsFixed(1)}', style: GoogleFonts.plusJakartaSans(color: AppColors.correct, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            onTap: () => _showUserDetailModal(u, admin),
          ),
        );
      },
    );
  }

  Widget _buildQuizzesTab(AdminProvider admin) {
    final filtered = admin.questions.where((q) {
      if (_selectedCategoryFilter == 'all') return true;
      return q.categoryId == _selectedCategoryFilter;
    }).toList();

    return Column(
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Row(
            children: [
              {'id': 'all', 'label': 'All (500+)'},
              {'id': 'gk', 'label': 'GK (100)'},
              {'id': 'science', 'label': 'Science (100)'},
              {'id': 'math', 'label': 'Math (100)'},
              {'id': 'sports', 'label': 'Sports (100)'},
              {'id': 'image', 'label': 'Image (100)'},
            ].map((c) {
              final isSel = _selectedCategoryFilter == c['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(c['label']!, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isSel ? Colors.white : AppColors.textSecondary)),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.cardBg,
                  side: BorderSide(color: isSel ? AppColors.primary : AppColors.cardBorder),
                  onSelected: (_) {
                    setState(() => _selectedCategoryFilter = c['id']!);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Questions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final q = filtered[idx];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: q.isPublished ? AppColors.cardBorder : const Color(0xFFFECACA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Lvl ${q.difficultyLevel}', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Ans: ${q.options[q.correctOptionIndex]} • +${q.pointsReward} Pts (${q.timerDuration}s)',
                              style: GoogleFonts.plusJakartaSans(color: AppColors.correct, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(q.isPublished ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              size: 18, color: q.isPublished ? AppColors.correct : AppColors.textMuted),
                          tooltip: 'Publish/Unpublish',
                          onPressed: () => admin.toggleQuestionPublish(q.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                          tooltip: 'Edit Question',
                          onPressed: () => _openQuestionEditor(q),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.wrong),
                          tooltip: 'Delete Question',
                          onPressed: () => admin.deleteQuestion(q.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWalletAndAdsTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conversion Rate Controls
          Text(
            'POINTS & CONVERSION SETTINGS',
            style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Conversion Rate', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${admin.settings.pointsPerRupee} pts = ₹1.00', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Standard: 1,000 Points = ₹10.00', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 11)),
                ),
                const Divider(height: 24),

                // Cash Redemption Master Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Enable Real-Money UPI Withdrawals', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: Text('Keep disabled until compliance review is completed', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 11)),
                  value: admin.settings.enableCashWithdrawals,
                  activeColor: AppColors.correct,
                  onChanged: (val) {
                    admin.updateSettings(admin.settings.copyWith(enableCashWithdrawals: val));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Google AdMob Settings
          Text(
            'GOOGLE ADMOB CONFIGURATION',
            style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.video_library_rounded, color: AppColors.goldDark),
                  title: Text('Rewarded Video Ads', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: Text('Watch ad to unlock quiz lifelines/hints', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 11)),
                  value: admin.settings.rewardedAdsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    admin.updateSettings(admin.settings.copyWith(rewardedAdsEnabled: val));
                  },
                ),
                const Divider(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.fullscreen_rounded, color: AppColors.accent),
                  title: Text('Interstitial Transition Ads', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: Text('Natural transitions between completed quiz rounds', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 11)),
                  value: admin.settings.interstitialAdsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    admin.updateSettings(admin.settings.copyWith(interstitialAdsEnabled: val));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // All Withdrawal Requests Review List
          Text(
            'WITHDRAWAL REQUESTS (${admin.withdrawals.length})',
            style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          if (admin.withdrawals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No requests yet', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
              ),
            )
          else
            ...admin.withdrawals.map((w) => _buildWithdrawalTile(w, admin)),
        ],
      ),
    );
  }

  Widget _buildWithdrawalTile(WithdrawalRequest w, AdminProvider admin) {
    Color statusCol = AppColors.warning;
    Color statusBg = const Color(0xFFFEF3C7);
    if (w.status == 'Approved' || w.status == 'Paid') {
      statusCol = AppColors.correct;
      statusBg = const Color(0xFFD1FAE5);
    } else if (w.status == 'Rejected') {
      statusCol = AppColors.wrong;
      statusBg = const Color(0xFFFEE2E2);
    }

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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(w.id, style: GoogleFonts.courierPrime(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(w.status, style: GoogleFonts.plusJakartaSans(color: statusCol, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${w.userName} (${w.userMobile})', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
          Text('UPI ID: ${w.upiId}', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 12)),
          Text('Amount: ₹${w.amount.toStringAsFixed(2)} (${w.pointsDeducted} pts)', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          if (w.status == 'Pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.correct, foregroundColor: Colors.white, elevation: 1, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Approve Payout'),
                    onPressed: () {
                      AudioManager().playClick();
                      admin.updateWithdrawalStatus(w.id, 'Paid', remarks: 'Approved and transferred via UPI');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.wrong), foregroundColor: AppColors.wrong, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Reject'),
                    onPressed: () {
                      AudioManager().playClick();
                      admin.updateWithdrawalStatus(w.id, 'Rejected', remarks: 'Invalid UPI or compliance discrepancy');
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
