import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';

class WithdrawalDialog extends StatefulWidget {
  const WithdrawalDialog({super.key});

  @override
  State<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<WithdrawalDialog> {
  final _pointsController = TextEditingController(text: '1000');
  late TextEditingController _upiController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _upiController = TextEditingController(text: user?.upiId ?? '');
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final int points = int.tryParse(_pointsController.text) ?? 0;
    final double calculatedPayout = wallet.settings.pointsPerRupee > 0
        ? points / wallet.settings.pointsPerRupee
        : 0.0;

    final isDark = AppColors.isDark(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorderOf(context), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                          ),
                          child: Icon(Icons.account_balance_wallet_rounded,
                              color: isDark ? const Color(0xFF818CF8) : AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'UPI Redemption',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.textSecondaryOf(context)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Available Balance preview
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Balance',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('₹${wallet.availableBalance.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Available Points',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('${wallet.availablePoints} Points',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Points Input Field
                Text('Points to Redeem',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.stars_rounded, color: AppColors.goldDark),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    hintText: 'Enter points (min ${wallet.settings.minWithdrawalPoints} pts = ₹1,000)',
                    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() {}),
                  validator: (value) {
                    final pts = int.tryParse(value ?? '');
                    if (pts == null || pts <= 0) {
                      return 'Please enter valid points';
                    }
                    if (pts < wallet.settings.minWithdrawalPoints) {
                      final minInr = (wallet.settings.minWithdrawalPoints / (wallet.settings.pointsPerRupee > 0 ? wallet.settings.pointsPerRupee : 100)).toStringAsFixed(0);
                      return 'Minimum withdrawal is ₹$minInr (${wallet.settings.minWithdrawalPoints} points)';
                    }
                    if (pts > wallet.availablePoints) {
                      return 'Exceeds available points';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Quick Select Chips
                Row(
                  children: [
                    ...[
                      {'pts': 100000, 'label': '₹1,000'},
                      {'pts': 200000, 'label': '₹2,000'},
                      {'pts': 500000, 'label': '₹5,000'},
                    ].map((chip) {
                      final quickPts = chip['pts'] as int;
                      final label = chip['label'] as String;
                      final isSelected = _pointsController.text == '$quickPts';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              )),
                          backgroundColor: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                          ),
                          onPressed: () {
                            AudioManager().playClick();
                            setState(() {
                              _pointsController.text = '$quickPts';
                            });
                          },
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text('MAX',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        backgroundColor: const Color(0xFFEEF2FF),
                        side: const BorderSide(color: AppColors.primary),
                        onPressed: () {
                          AudioManager().playClick();
                          setState(() {
                            _pointsController.text = '${wallet.availablePoints}';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Saved UPI ID
                Text('Confirm UPI ID (Virtual Payment Address)',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _upiController,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    hintText: 'e.g., yourname@oksbi / 9876543210@paytm',
                    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || !val.contains('@') || val.trim().length < 5) {
                      return 'Enter a valid UPI ID (e.g. name@bank)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Real Payout Summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated Redemption Value:',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('₹${calculatedPayout.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB45309),
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Compliance Note
                if (!wallet.settings.enableCashWithdrawals)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Real-money payouts are in testing mode until regulatory compliance is finalized.',
                            style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF9A3412), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: wallet.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              AudioManager().playClick();
                              final pts = int.parse(_pointsController.text.trim());
                              final upi = _upiController.text.trim();
                              final user = context.read<AuthProvider>().currentUser;

                              if (user != null && user.upiId != upi) {
                                await context.read<AuthProvider>().updateProfile(
                                      name: user.name,
                                      mobile: user.mobile,
                                      email: user.email,
                                      upiId: upi,
                                    );
                              }

                              final success = await wallet.submitWithdrawal(
                                pointsToRedeem: pts,
                                upiId: upi,
                              );

                              if (!context.mounted) return;

                              if (success) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Withdrawal request submitted successfully! Tracking ID generated.'),
                                    backgroundColor: AppColors.correct,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(wallet.errorMessage ??
                                        'Unable to process withdrawal request.'),
                                    backgroundColor: AppColors.wrong,
                                  ),
                                );
                              }
                            }
                          },
                    child: wallet.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Submit Withdrawal Request',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
