import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    // Navigate to home after ~3.5 seconds
    _navTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Ambient blobs ────────────────────────────────────
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixed.withValues(alpha: 0.25),
              ),
            ).animate().fadeIn(duration: 800.ms),
          ),
          Positioned(
            bottom: 60,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer.withValues(alpha: 0.18),
              ),
            ).animate().fadeIn(duration: 900.ms, delay: 100.ms),
          ),

          // ── Main content ─────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(),

                  // ── Branding section ──────────────────────────
                  Column(
                    children: [
                      // Icon container
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 24),

                      // App name
                      Text(
                        'Smart Recipe Planner',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.28,
                          letterSpacing: -0.02 * 28,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 150.ms, duration: 600.ms)
                          .slideY(begin: 0.3, curve: Curves.easeOut),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Temukan resep terbaik berdasarkan\nbahan yang tersedia.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 600.ms)
                          .slideY(begin: 0.3, curve: Curves.easeOut),
                    ],
                  ),

                  const Spacer(),

                  // ── Loading indicator ─────────────────────────
                  Column(
                    children: [
                      // Thin circular spinner
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withValues(alpha: 0.6),
                          ),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PREPARING SEARCH ENGINE...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          letterSpacing: 0.08 * 11,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
