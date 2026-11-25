import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/audio/audio_manager.dart';
import '../providers/language_provider.dart';
import 'home/home_screen.dart';
import 'categories/categories_screen.dart';
import 'wallet/wallet_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    AudioManager().playHomeBgm();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      AudioManager().playClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const CategoriesScreen(),
      const WalletScreen(),
      ProfileScreen(onNavigateTab: _onTabSelected),
    ];

    final lang = context.watch<LanguageProvider>();
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: 1,
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 8,
                  offset: const Offset(0, -1),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B).withOpacity(0.95),
                            const Color(0xFF0F172A).withOpacity(0.90),
                          ]
                        : [
                            Colors.white.withOpacity(0.92),
                            Colors.white.withOpacity(0.76),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155).withOpacity(0.8) : Colors.white.withOpacity(0.95),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(child: _buildLiquidNavItem(0, Icons.home_rounded, lang.tr('nav_home'))),
                    Expanded(child: _buildLiquidNavItem(1, Icons.grid_view_rounded, lang.tr('nav_categories'))),
                    Expanded(child: _buildLiquidNavItem(2, Icons.account_balance_wallet_rounded, lang.tr('nav_wallet'))),
                    Expanded(child: _buildLiquidNavItem(3, Icons.person_rounded, lang.tr('nav_profile'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidNavItem(int index, IconData icon, String label) {
    final isSelected = (_currentIndex == index);
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF4F46E5), // Indigo
                              const Color(0xFF6366F1), // Royal Indigo
                            ]
                          : [
                              const Color(0xFF312E81), // Deep Indigo
                              const Color(0xFF4338CA), // Royal Indigo
                            ],
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF4338CA)).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected
                    ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF312E81))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
