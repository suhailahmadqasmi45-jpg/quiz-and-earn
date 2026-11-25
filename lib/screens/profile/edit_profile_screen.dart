import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final bool focusUpiField;

  const EditProfileScreen({super.key, this.focusUpiField = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _upiController;
  final FocusNode _upiFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _mobileController = TextEditingController(text: user?.mobile ?? '');
    _upiController = TextEditingController(text: user?.upiId ?? '');

    if (widget.focusUpiField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _upiFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _upiController.dispose();
    _upiFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      AudioManager().playClick();
      final auth = context.read<AuthProvider>();

      await auth.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        upiId: _upiController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile & UPI updated successfully!'),
          backgroundColor: AppColors.correct,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          widget.focusUpiField ? 'Update UPI ID' : 'Edit Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        backgroundColor: AppColors.backgroundOf(context),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.focusUpiField) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wallet Payout Setup',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add your valid UPI ID to receive prize payouts directly into your bank account.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _buildFieldLabel('Full Name', Icons.person_rounded),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: _buildInputDecoration('Full Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Email Address', Icons.email_rounded),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: _buildInputDecoration('Email Address').copyWith(
                    fillColor: const Color(0xFFF1F5F9),
                    suffixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Mobile Number', Icons.phone_android_rounded),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: _buildInputDecoration('10-digit mobile number').copyWith(
                    counterText: '',
                    prefixText: '+91 ',
                  ),
                  validator: (v) => Validators.validateIndianMobile(v),
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('UPI ID (Optional)', Icons.account_balance_rounded),
                TextFormField(
                  controller: _upiController,
                  focusNode: _upiFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: _buildInputDecoration('e.g., yourname@oksbi / mobile@paytm (Optional)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return null; // UPI ID is completely optional!
                    }
                    if (!v.contains('@') || v.trim().length < 5) {
                      return 'Enter a valid UPI ID (e.g., name@bank)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Disclaimer requirement
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.goldDark, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saving a UPI ID does not verify bank account ownership or guarantee withdrawal eligibility. Please ensure you enter your own correct VPA.',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF92400E),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _saveChanges,
                    child: Text(
                      'Save Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  Widget _buildFieldLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.cardBgOf(context),
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMutedOf(context), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.cardBorderOf(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.cardBorderOf(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
