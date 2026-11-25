import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/atm_card_widget.dart';
import 'withdrawal_dialog.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openWithdrawalModal() {
    AudioManager().playClick();
    showDialog(
      context: context,
      builder: (_) => const WithdrawalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          'Digital Wallet',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: isDark ? const Color(0xFF818CF8) : AppColors.primary),
            onPressed: () {
              AudioManager().playClick();
              _showConversionRulesDialog(context, wallet);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive 3D ATM Card
            AtmCardWidget(
              user: user,
              points: wallet.availablePoints,
              balance: wallet.availableBalance,
            ),
            const SizedBox(height: 12),

            // Hint Text for card
            Center(
              child: Text(
                '✦ Tap the ATM Card to flip and view player details ✦',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Main Action Button: Withdraw / Redeem
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.send_to_mobile_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Withdraw Earnings via UPI',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: _openWithdrawalModal,
              ),
            ),
            const SizedBox(height: 22),

            // 3. Financial Summary Metrics Cards Grid
            _buildMetricsGrid(context, wallet),
            const SizedBox(height: 24),

            // 4. Tab bar for Transactions, Rewards, and Withdrawals
            Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMutedOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorderOf(context)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                unselectedLabelColor: AppColors.textSecondaryOf(context),
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Transactions'),
                  Tab(text: 'Quiz Rewards'),
                  Tab(text: 'Withdrawals'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Contents
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionsList(wallet),
                  _buildQuizRewardsList(wallet),
                  _buildWithdrawalsList(wallet),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, WalletProvider wallet) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context: context,
                title: 'Available Balance',
                value: '₹${wallet.availableBalance.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_rounded,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context: context,
                title: 'Available Points',
                value: '${wallet.availablePoints} Points',
                icon: Icons.stars_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: AppColors.goldDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context: context,
                title: 'Total Withdrawn',
                value: '₹${wallet.totalWithdrawn.toStringAsFixed(2)}',
                icon: Icons.check_circle_rounded,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: AppColors.correct,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context: context,
                title: 'Pending Payout',
                value: '₹${wallet.pendingWithdrawalsTotal.toStringAsFixed(2)}',
                icon: Icons.hourglass_top_rounded,
                iconBg: const Color(0xFFFFEDD5),
                iconColor: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
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
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(WalletProvider wallet) {
    if (wallet.transactions.isEmpty) {
      return _buildEmptyPlaceholder('No transactions recorded yet.');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: wallet.transactions.length,
      itemBuilder: (context, index) {
        final tx = wallet.transactions[index];
        final isCredit = tx.points >= 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderOf(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCredit ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isCredit ? AppColors.correct : AppColors.wrong,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp)} • ${tx.status}',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? "+" : ""}${tx.points} pts',
                    style: GoogleFonts.plusJakartaSans(
                      color: isCredit ? AppColors.correct : AppColors.wrong,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${isCredit ? "+" : ""}₹${tx.amount.abs().toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizRewardsList(WalletProvider wallet) {
    if (wallet.quizHistory.isEmpty) {
      return _buildEmptyPlaceholder('No quiz history recorded yet. Play a quiz to earn points!');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: wallet.quizHistory.length,
      itemBuilder: (context, index) {
        final item = wallet.quizHistory[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderOf(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.quiz_rounded, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.categoryTitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.correctAnswers}/${item.questionsAttempted} Correct • ${DateFormat('dd MMM, hh:mm a').format(item.date)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${item.pointsEarned} pts',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.goldDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWithdrawalsList(WalletProvider wallet) {
    if (wallet.withdrawals.isEmpty) {
      return _buildEmptyPlaceholder('No withdrawal requests submitted yet.');
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: wallet.withdrawals.length,
      itemBuilder: (context, index) {
        final item = wallet.withdrawals[index];

        Color statusColor = AppColors.warning;
        Color statusBg = const Color(0xFFFEF3C7);
        if (item.status == 'Paid' || item.status == 'Approved') {
          statusColor = AppColors.correct;
          statusBg = const Color(0xFFD1FAE5);
        } else if (item.status == 'Rejected') {
          statusColor = AppColors.wrong;
          statusBg = const Color(0xFFFEE2E2);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorderOf(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.02),
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
                  Text(
                    item.id,
                    style: GoogleFonts.courierPrime(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status,
                      style: GoogleFonts.plusJakartaSans(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'UPI: ${item.upiId}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${item.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Redeemed ${item.pointsDeducted} pts on ${DateFormat('dd MMM yyyy, hh:mm a').format(item.requestDate)}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              if (item.adminRemarks != null && item.adminRemarks!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Admin Note: ${item.adminRemarks}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showConversionRulesDialog(BuildContext context, WalletProvider wallet) {
    final isDark = AppColors.isDark(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBgOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.cardBorderOf(context)),
        ),
        title: Row(
          children: [
            Icon(Icons.currency_rupee_rounded, color: isDark ? const Color(0xFF818CF8) : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Reward & Conversion Policy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleItem(context, 'Rate', '100 Points = ₹1.00 (100 pts = ₹1.00)'),
            _buildRuleItem(context, 'Minimum Limit', '₹1,000 (${wallet.settings.minWithdrawalPoints} Points)'),
            _buildRuleItem(context, 'Mode', 'Direct UPI Transfer (No bank account or OTP needed)'),
            _buildRuleItem(context, 'Cash Status', wallet.settings.enableCashWithdrawals ? 'Active' : 'In Compliance Testing Mode'),
            const SizedBox(height: 10),
            Text(
              'Earned points represent in-game trivia rewards. Payouts are reviewed securely by administrator.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryOf(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondaryOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimaryOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
