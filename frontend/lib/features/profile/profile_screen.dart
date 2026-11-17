import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final surfaceCard = isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.primaryFixed : AppColors.primary;
    final primaryContainer = isDark ? AppColors.primaryContainer : AppColors.primaryContainer;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          'Application',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            letterSpacing: -0.01 * 24,
          ),
        ),
        actions: [
          // Theme toggle (kept for functionality even if not strictly in Stitch design)
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: textSecondary,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 100 + MediaQuery.of(context).padding.bottom),
          children: [
            // ── Menu Group 1 ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.dataset_outlined,
                    label: 'Dataset Information',
                    textPrimary: textPrimary,
                    primaryColor: primaryColor,
                    primaryContainer: primaryContainer,
                    textSecondary: textSecondary,
                    onTap: () => context.push('/admin'),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── Menu Group 2 ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.info_outline,
                    label: 'About Application',
                    textPrimary: textPrimary,
                    primaryColor: primaryColor,
                    primaryContainer: primaryContainer,
                    textSecondary: textSecondary,
                    iconColor: textSecondary,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Smart Recipe Planner',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.eco_outlined, size: 48),
                      );
                    },
                  ),
                  _Divider(borderColor: borderColor),
                  _MenuTile(
                    icon: Icons.science_outlined,
                    label: 'About Research',
                    textPrimary: textPrimary,
                    primaryColor: primaryColor,
                    primaryContainer: primaryContainer,
                    textSecondary: textSecondary,
                    iconColor: textSecondary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Research info coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05),

            const SizedBox(height: 32),

            // ── Version Footer ──────────────────────────────────────
            Center(
              child: Text(
                'VERSION 1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary.withValues(alpha: 0.6),
                  letterSpacing: 0.05 * 12,
                ),
              ).animate().fadeIn(delay: 200.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color textPrimary;
  final Color primaryColor;
  final Color primaryContainer;
  final Color textSecondary;
  final Color? iconColor;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.textPrimary,
    required this.primaryColor,
    required this.primaryContainer,
    required this.textSecondary,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeIconColor = widget.iconColor ?? widget.primaryColor;

    return InkWell(
      onTap: widget.onTap,
      onHover: (hovered) => setState(() => _isHovered = hovered),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: _isHovered ? widget.primaryContainer : activeIconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: _isHovered ? widget.primaryColor : widget.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: widget.textSecondary.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color borderColor;

  const _Divider({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 1,
        color: borderColor.withValues(alpha: 0.5),
      ),
    );
  }
}
