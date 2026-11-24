import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/audio/audio_manager.dart';
import '../models/user_model.dart';

class AtmCardWidget extends StatefulWidget {
  final UserModel? user;
  final int points;
  final double balance;
  final VoidCallback? onCardTapped;

  const AtmCardWidget({
    super.key,
    required this.user,
    required this.points,
    required this.balance,
    this.onCardTapped,
  });

  @override
  State<AtmCardWidget> createState() => _AtmCardWidgetState();
}

class _AtmCardWidgetState extends State<AtmCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    AudioManager().playClick();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
    widget.onCardTapped?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFrontVisible = angle <= pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // 3D Perspective depth
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: -2,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: isFrontVisible
                    ? _buildCardFront()
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildCardBack(),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardFront() {
    final userName = widget.user?.name.toUpperCase() ?? 'VALUED PLAYER';
    final sinceYear = widget.user?.memberSince.year ?? DateTime.now().year;

    return Stack(
      children: [
        // Premium Dark Indigo & Obsidian Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.atmCardGradient,
          ),
        ),

        // Subtle Geometric Gold Circuit Lines
        Positioned.fill(
          child: CustomPaint(
            painter: CardPatternPainter(),
          ),
        ),

        // Shimmering Gold Accent Border
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.35),
              width: 1.2,
            ),
          ),
        ),

        // Card Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Top Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withOpacity(0.2),
                          border: Border.all(color: AppColors.gold, width: 1),
                        ),
                        child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QUIZ & EARN',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Contactless Wave Icon
                      Icon(
                        Icons.contactless_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PLATINUM',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. Metallic Chip & Masked ID Row
              Row(
                children: [
                  // Gold Smart Chip
                  Container(
                    width: 44,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFDF73), Color(0xFFC59B27), Color(0xFF9E7812)],
                      ),
                      border: Border.all(color: const Color(0xFFFFF1A8), width: 1),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/atm_chip.png',
                        width: 40,
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.memory_rounded,
                          color: Colors.black87,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Masked Card Number
                  Text(
                    '••••  ••••  ••••  ${widget.user?.uid.substring(max(0, (widget.user?.uid.length ?? 4) - 4)) ?? "8901"}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),

              // 3. Balance & Points Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE BALANCE',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textOnDarkMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${widget.balance.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL POINTS',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textOnDarkMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.gold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.points} Points',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
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

              // 4. Card Holder & Expiry Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textOnDarkMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'MEMBER SINCE',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textOnDarkMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$sinceYear',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.goldLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Tap to Flip indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flip_rounded, color: Colors.white70, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          'FLIP',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack() {
    final uid = widget.user?.uid ?? 'USR-8901';
    final quizCount = widget.user?.totalQuizPlayed ?? 0;

    return Stack(
      children: [
        // Back Obsidian Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF1E1B4B),
                Color(0xFF0F172A),
                Color(0xFF030712),
              ],
            ),
          ),
        ),

        // Shimmering Gold Accent Border
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.35),
              width: 1.2,
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            // Black Magnetic Stripe
            Container(
              height: 40,
              width: double.infinity,
              color: const Color(0xFF020617),
            ),
            const SizedBox(height: 14),

            // Signature Band & Player Identifier
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      color: Colors.white.withOpacity(0.92),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PLAYER ID: $uid',
                        style: GoogleFonts.courierPrime(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Holographic Seal
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                    ),
                    child: const Center(
                      child: Icon(Icons.security_rounded, color: Colors.black, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Back Stats & Security Notice
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUIZZES PLAYED: $quizCount',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.goldLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'POINTS EARNED: ${widget.user?.totalPoints ?? widget.points} Points',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.correct,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'LIFETIME REWARDS: ₹${((widget.user?.totalPoints ?? widget.points) / 100).toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'MEMBER SINCE: ${DateFormat("MMM yyyy").format(widget.user?.memberSince ?? DateTime.now())}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textOnDarkMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // Decorative Security QR Graphic
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5B942).withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    path1.moveTo(-20, size.height * 0.7);
    path1.cubicTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width * 0.6,
      size.height * 0.2,
      size.width + 20,
      size.height * 0.4,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(-20, size.height * 0.85);
    path2.cubicTo(
      size.width * 0.35,
      size.height * 1.05,
      size.width * 0.65,
      size.height * 0.35,
      size.width + 20,
      size.height * 0.55,
    );
    canvas.drawPath(path2, paint);

    final circlePaint = Paint()
      ..color = const Color(0xFF6D28D9).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 70, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
