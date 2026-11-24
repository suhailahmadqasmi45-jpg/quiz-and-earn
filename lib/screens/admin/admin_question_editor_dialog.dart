import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/audio_manager.dart';
import '../../models/question_model.dart';

class AdminQuestionEditorDialog extends StatefulWidget {
  final QuestionModel? existingQuestion;
  final Function(QuestionModel) onSave;

  const AdminQuestionEditorDialog({
    super.key,
    this.existingQuestion,
    required this.onSave,
  });

  @override
  State<AdminQuestionEditorDialog> createState() => _AdminQuestionEditorDialogState();
}

class _AdminQuestionEditorDialogState extends State<AdminQuestionEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _qTextController;
  late TextEditingController _opt0Controller;
  late TextEditingController _opt1Controller;
  late TextEditingController _opt2Controller;
  late TextEditingController _opt3Controller;
  late TextEditingController _expController;
  late TextEditingController _hintController;
  late TextEditingController _imgController;

  String _selectedCategory = 'gk';
  int _correctIndex = 0;
  int _difficultyLevel = 1;
  int _timerDuration = 30;
  int _pointsReward = 5;

  final categories = const [
    {'id': 'gk', 'title': 'General Knowledge'},
    {'id': 'science', 'title': 'Science & Technology'},
    {'id': 'math', 'title': 'Mathematics & Reasoning'},
    {'id': 'sports', 'title': 'Sports & Entertainment'},
    {'id': 'image', 'title': 'Image Quiz & Mystery'},
  ];

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;
    _qTextController = TextEditingController(text: q?.questionText ?? '');
    _opt0Controller = TextEditingController(text: q != null && q.options.isNotEmpty ? q.options[0] : '');
    _opt1Controller = TextEditingController(text: q != null && q.options.length > 1 ? q.options[1] : '');
    _opt2Controller = TextEditingController(text: q != null && q.options.length > 2 ? q.options[2] : '');
    _opt3Controller = TextEditingController(text: q != null && q.options.length > 3 ? q.options[3] : '');
    _expController = TextEditingController(text: q?.explanation ?? '');
    _hintController = TextEditingController(text: q?.hintText ?? '');
    _imgController = TextEditingController(text: q?.imageUrl ?? '');

    if (q != null) {
      _selectedCategory = q.categoryId;
      _correctIndex = q.correctOptionIndex;
      _difficultyLevel = q.difficultyLevel;
      _timerDuration = q.timerDuration;
      _pointsReward = q.pointsReward;
    }
  }

  @override
  void dispose() {
    _qTextController.dispose();
    _opt0Controller.dispose();
    _opt1Controller.dispose();
    _opt2Controller.dispose();
    _opt3Controller.dispose();
    _expController.dispose();
    _hintController.dispose();
    _imgController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    if (_formKey.currentState!.validate()) {
      AudioManager().playClick();

      String diffTitle = 'Easy';
      if (_difficultyLevel > 40) {
        diffTitle = 'Master';
      } else if (_difficultyLevel > 20) {
        diffTitle = 'Expert';
      } else if (_difficultyLevel > 10) {
        diffTitle = 'Hard';
      } else if (_difficultyLevel > 5) {
        diffTitle = 'Medium';
      }

      final saved = QuestionModel(
        id: widget.existingQuestion?.id ?? 'q_custom_${const Uuid().v4().substring(0, 8)}',
        categoryId: _selectedCategory,
        questionText: _qTextController.text.trim(),
        imageUrl: _imgController.text.trim().isNotEmpty ? _imgController.text.trim() : null,
        options: [
          _opt0Controller.text.trim(),
          _opt1Controller.text.trim(),
          _opt2Controller.text.trim(),
          _opt3Controller.text.trim(),
        ],
        correctOptionIndex: _correctIndex,
        difficultyLevel: _difficultyLevel,
        difficultyTitle: diffTitle,
        timerDuration: _timerDuration,
        pointsReward: _pointsReward,
        explanation: _expController.text.trim(),
        hintText: _hintController.text.trim(),
        isPublished: widget.existingQuestion?.isPublished ?? true,
      );

      widget.onSave(saved);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingQuestion == null ? 'Add Quiz Question' : 'Edit Question',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Category selector
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: AppColors.cardBg,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: _buildInputDecor('Quiz Category'),
                  items: categories.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id']!,
                      child: Text(c['title']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),

                // Question Text
                TextFormField(
                  controller: _qTextController,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: _buildInputDecor('Question Text'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter question' : null,
                ),
                const SizedBox(height: 12),

                // Options
                Text('Answer Options (Select correct option radio):',
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _buildOptionField('Option A', _opt0Controller, 0),
                const SizedBox(height: 6),
                _buildOptionField('Option B', _opt1Controller, 1),
                const SizedBox(height: 6),
                _buildOptionField('Option C', _opt2Controller, 2),
                const SizedBox(height: 6),
                _buildOptionField('Option D', _opt3Controller, 3),
                const SizedBox(height: 12),

                // Difficulty & Timer & Points
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '$_difficultyLevel',
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecor('Level (1-40+)'),
                        onChanged: (v) => _difficultyLevel = int.tryParse(v) ?? 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: '$_timerDuration',
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecor('Timer (Sec)'),
                        onChanged: (v) => _timerDuration = int.tryParse(v) ?? 30,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: '$_pointsReward',
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecor('Points'),
                        onChanged: (v) => _pointsReward = int.tryParse(v) ?? 5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Explanation & Hint
                TextFormField(
                  controller: _expController,
                  maxLines: 2,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 12),
                  decoration: _buildInputDecor('Explanation / Fact details'),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _hintController,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 12),
                  decoration: _buildInputDecor('Hint Clue (Unlocked via Ad)'),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveQuestion,
                    child: Text(
                      'Save Question',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
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

  Widget _buildOptionField(String label, TextEditingController ctrl, int index) {
    return Row(
      children: [
        Radio<int>(
          value: index,
          groupValue: _correctIndex,
          activeColor: AppColors.correct,
          onChanged: (val) {
            if (val != null) setState(() => _correctIndex = val);
          },
        ),
        Expanded(
          child: TextFormField(
            controller: ctrl,
            style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontSize: 13),
            decoration: _buildInputDecor(label),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecor(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }
}
