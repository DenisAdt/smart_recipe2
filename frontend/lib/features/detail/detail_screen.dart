import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/models/recipe.dart';
import '../../shared/models/search_result.dart';
import '../../shared/providers/recipe_provider.dart';
import '../../shared/providers/search_provider.dart';
import '../../shared/providers/theme_provider.dart';

class DetailScreen extends ConsumerWidget {
  final int recipeId;
  final dynamic searchResult; // SearchResult if coming from search

  const DetailScreen({
    super.key,
    required this.recipeId,
    this.searchResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));
    final sr = searchResult != null ? searchResult as SearchResult : null;
    final userIngredients = ref.watch(ingredientsProvider);

    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final surfaceCard = isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      body: recipeAsync.when(
        data: (recipe) => _buildContent(
            context, recipe, sr, userIngredients, isDark, bg, textPrimary, textSecondary, surfaceCard, borderColor),
        loading: () => _buildShimmer(isDark, bg, surfaceCard),
        error: (e, _) => _buildError(context, e.toString(), isDark, textSecondary),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Recipe recipe,
    SearchResult? sr,
    List<String> userIngredients,
    bool isDark,
    Color bg,
    Color textPrimary,
    Color textSecondary,
    Color surfaceCard,
    Color borderColor,
  ) {
    final recipeIngredients = recipe.ingredientList;

    final Set<String> matchedSet = {};
    final Set<String> additionalSet = {};

    for (final rIng in recipeIngredients) {
      final normalizedRIng = _normalizeIngredient(rIng);
      if (normalizedRIng.isEmpty) continue;

      final matched = userIngredients.any((uIng) {
        final normalizedUIng = _normalizeIngredient(uIng);
        if (normalizedUIng.isEmpty) return false;
        return normalizedRIng.contains(normalizedUIng);
      });
      
      final displayName = _extractIngredientName(rIng);
      if (displayName.isEmpty) continue;

      if (matched) {
        matchedSet.add(displayName);
      } else {
        additionalSet.add(displayName);
      }
    }
    
    List<String> matchedDisplay = matchedSet.toList();
    List<String> missingDisplay = additionalSet.toList();

    return CustomScrollView(
      slivers: [
        // ── Hero image + back button ────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          floating: false,
          pinned: true,
          backgroundColor: bg,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/results');
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface2.withValues(alpha: 0.8)
                      : AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'recipe_img_${recipe.id}',
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: recipe.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? AppColors.darkSurface2 : AppColors.surfaceContainer,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? AppColors.darkSurface2 : AppColors.surfaceContainer,
                        child: Icon(Icons.restaurant,
                            size: 64, color: textSecondary.withValues(alpha: 0.4)),
                      ),
                    )
                  : Container(
                      color: isDark ? AppColors.darkSurface2 : AppColors.surfaceContainer,
                      child: Icon(Icons.restaurant,
                          size: 64, color: textSecondary.withValues(alpha: 0.4)),
                    ),
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 100 + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  recipe.title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    height: 1.33,
                    letterSpacing: -0.01 * 24,
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                // Meta Info Row
                Row(
                  children: [
                    _MetaBadge(
                      icon: Icons.schedule_outlined,
                      label: '${recipe.cookingTime} min',
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                    const SizedBox(width: 8),
                    _MetaBadge(
                      icon: Icons.signal_cellular_alt_outlined,
                      label: recipe.difficulty ?? 'Medium',
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                    const SizedBox(width: 8),
                    _MetaBadge(
                      icon: Icons.category_outlined,
                      label: recipe.category,
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Ingredients List
                Row(
                  children: [
                    Icon(Icons.shopping_basket_outlined, color: textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ingredients',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
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
                    children: recipe.ingredientList.asMap().entries.map((e) {
                      final isLast = e.key == recipe.ingredientList.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.primaryFixed : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.value,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),

                const SizedBox(height: 32),

                // Cooking Steps
                Row(
                  children: [
                    Icon(Icons.blender_outlined, color: textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Cooking Steps',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                ...recipe.instructionSteps.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.primaryFixed : AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.inverseSurface : AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Step ${e.key + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  e.value,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (350 + (e.key * 50)).ms).slideY(begin: 0.05);
                }),

                // ── "Why this recipe?" Research Footer ───────────
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.surfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Icon(Icons.psychology_outlined,
                          color: isDark ? AppColors.primaryFixed : AppColors.tertiary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Why this recipe?',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.inverseSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: -40,
                          right: -40,
                          child: Transform.rotate(
                            angle: 0.2,
                            child: Icon(
                              Icons.analytics,
                              size: 160,
                              color: Colors.white.withValues(alpha: 0.03),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'USES YOUR INGREDIENTS',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inverseOnSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (matchedDisplay.isEmpty)
                              const Text('-', style: TextStyle(color: AppColors.inverseOnSurface)),
                            ...matchedDisplay.map((ing) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check, size: 16, color: AppColors.primaryFixed),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ing,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.inverseOnSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 24),
                            
                            Text(
                              'ADDITIONAL INGREDIENTS NEEDED',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inverseOnSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (missingDisplay.isEmpty)
                              const Text('-', style: TextStyle(color: AppColors.inverseOnSurface)),
                            ...missingDisplay.map((ing) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, size: 6, color: AppColors.inverseOnSurface.withValues(alpha: 0.4)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          ing,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.inverseOnSurface.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                
                            const SizedBox(height: 24),
                            Container(
                              height: 1,
                              color: AppColors.inverseOnSurface.withValues(alpha: 0.1),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'BM25 SCORE',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inverseOnSurface.withValues(alpha: 0.6),
                                    letterSpacing: 0.05 * 12,
                                  ),
                                ),
                                Text(
                                  sr?.formattedScore ?? '--',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                    color: AppColors.inverseOnSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer(bool isDark, Color bg, Color surfaceCard) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurface2 : AppColors.surfaceContainer,
      highlightColor: isDark ? AppColors.darkSurface : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 260, color: surfaceCard),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 32, width: 200, color: surfaceCard),
                const SizedBox(height: 16),
                Container(height: 24, width: double.infinity, color: surfaceCard),
                const SizedBox(height: 32),
                Container(height: 24, width: 120, color: surfaceCard),
                const SizedBox(height: 16),
                Container(height: 120, width: double.infinity, color: surfaceCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat resep:\n$message',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}

/// Normalize an ingredient string for matching comparison only.
/// Returns a lowercase string with quantities, units, punctuation removed.
String _normalizeIngredient(String raw) {
  var s = raw.toLowerCase().trim();

  // Remove content inside parentheses (e.g. "(±200 gram)")
  s = s.replaceAll(RegExp(r'\(.*?\)'), ' ');

  // Remove punctuation except spaces
  s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');

  // Remove leading numbers including fractions (e.g. "1", "1/2", "250")
  s = s.replaceAll(RegExp(r'^\s*\d+(?:[.,/]\d+)?\s*'), '');

  // Remove measurement units (word-boundary anchored)
  const units = [
    'gram', 'gr', 'kg', 'ml', 'liter', 'l',
    'sdm', 'sdt', 'sendok', 'makan', 'teh',
    'buah', 'bh', 'siung', 'lembar', 'batang',
    'ruas', 'butir', 'biji', 'ekor', 'papan',
    'ons', 'ikat', 'bungkus', 'potong',
  ];
  final unitRegex = RegExp(
    r'\b\d*(?:[.,]\d+)?(?:/\d+)?\s*(?:' + units.join('|') + r')\b',
    caseSensitive: false,
  );
  s = s.replaceAll(unitRegex, ' ');

  // Remove cooking/prep descriptors (word-boundary anchored)
  const descriptors = [
    'potong', 'iris', 'halus', 'kasar', 'tipis', 'memanjang',
    'melintang', 'dadu', 'cincang', 'geprek', 'memarkan', 'memar',
    'rebus', 'goreng', 'bakar', 'tumis', 'sangrai', 'kukus',
    'parut', 'serut', 'blender', 'haluskan',
    'secukupnya', 'sesuai', 'selera', 'saja', 'atau',
    'dan', 'dengan', 'untuk', 'campur',
  ];
  final descRegex = RegExp(
    r'\b(?:' + descriptors.join('|') + r')\b',
    caseSensitive: false,
  );
  s = s.replaceAll(descRegex, ' ');

  // Remove stray numbers
  s = s.replaceAll(RegExp(r'\b\d+(?:[.,/]\d+)?\b'), ' ');

  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Extract a clean, displayable ingredient name from a raw string.
/// Applies full normalization then title-cases the result.
String _extractIngredientName(String raw) {
  final normalized = _normalizeIngredient(raw);
  if (normalized.isEmpty) return raw.trim();
  // Title-case: capitalize the first letter of each word
  return normalized.split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color textPrimary;

  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.primaryFixed : AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
