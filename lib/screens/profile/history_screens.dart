import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/wallet_provider.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final history = wallet.quizHistory;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          'My Quiz History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ),
      body: history.isEmpty
          ? Center(
              child: Text(
                'No quizzes played yet.',
                style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryOf(context), fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              physics: const BouncingScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, idx) {
                final item = history[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorderOf(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE9FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.quiz_rounded, color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.categoryTitle,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '✓ ${item.correctAnswers} Correct',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.correct,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '✗ ${item.questionsAttempted - item.correctAnswers} Incorrect',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.wrong,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Score: ${((item.correctAnswers / (item.questionsAttempted > 0 ? item.questionsAttempted : 1)) * 100).toInt()}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.questionsAttempted} Total Qs • ${DateFormat("dd MMM yyyy, hh:mm a").format(item.date)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            ),
    );
  }
}

class EarningsHistoryScreen extends StatelessWidget {
  const EarningsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final transactions = wallet.transactions;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          'Earnings History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ),
      body: transactions.isEmpty
          ? Center(
              child: Text(
                'No earnings records found.',
                style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryOf(context), fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              physics: const BouncingScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, idx) {
                final tx = transactions[idx];
                final isCredit = tx.points >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorderOf(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(AppColors.isDark(context) ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCredit ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isCredit ? AppColors.correct : AppColors.wrong,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary,
                                fontSize: 14,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${isCredit ? "+" : ""}₹${tx.amount.abs().toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
