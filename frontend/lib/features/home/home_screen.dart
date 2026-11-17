import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/recipe.dart';
import '../../shared/providers/recipe_provider.dart';
import '../../shared/providers/search_provider.dart';
import '../../shared/providers/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final popularAsync = ref.watch(popularRecipesProvider);
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final surfaceCard = isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final inputFill = isDark ? AppColors.darkSurface : AppColors.inputFill;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.primaryFixed
                                  : AppColors.primary,
                            ),
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 4),
                          Text(
                            'Smart Recipe Planner',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
                        ],
                      ),
                    ),
                    // Theme toggle
                    GestureDetector(
                      onTap: () => ref.read(themeProvider.notifier).toggle(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 20,
                          color: textSecondary,
                        ),
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                  ],
                ),
              ),
            ),

            // ── Popular Ingredients ───────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Popular Ingredients',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: AppConstants.quickIngredients.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final ingredient = AppConstants.quickIngredients[index];
                        final isFirst = index == 0;
                        return GestureDetector(
                          onTap: () {
                            ref.read(ingredientsProvider.notifier).clear();
                            ref.read(ingredientsProvider.notifier).add(ingredient);
                            context.go('/search');
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? (isDark ? AppColors.primaryFixed : AppColors.primary)
                                  : inputFill,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              ingredient,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isFirst
                                    ? (isDark ? AppColors.inverseSurface : AppColors.onPrimary)
                                    : textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            ),

            // ── Explore Recipes ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Explore Recipes',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/search'),
                      child: Text(
                        'View all',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.primaryFixed : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ),

            // ── Recipe cards (popular recipes from API) ────────────
            SliverToBoxAdapter(
              child: popularAsync.when(
                data: (recipes) => _RecipeCardList(
                  recipes: recipes,
                  isDark: isDark,
                  surfaceCard: surfaceCard,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                loading: () => _ShimmerCards(isDark: isDark),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    'Unable to load recipes. Make sure the backend is running.',
                    style: GoogleFonts.inter(fontSize: 14, color: textSecondary),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ── Recipe card list ──────────────────────────────────────────────────────────
class _RecipeCardList extends StatelessWidget {
  final List<Recipe> recipes;
  final bool isDark;
  final Color surfaceCard;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _RecipeCardList({
    required this.recipes,
    required this.isDark,
    required this.surfaceCard,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final displayed = recipes.take(6).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(displayed.length, (i) {
          final recipe = displayed[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RecipeCard(
              recipe: recipe,
              isDark: isDark,
              surfaceCard: surfaceCard,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              delay: (i * 50).ms,
            ),
          );
        }),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isDark;
  final Color surfaceCard;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Duration delay;

  const _RecipeCard({
    required this.recipe,
    required this.isDark,
    required this.surfaceCard,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.categoryColor(recipe.category);

    return GestureDetector(
      onTap: () => context.go('/detail/${recipe.id}'),
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              width: double.infinity,
              height: 192,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: isDark
                                ? AppColors.darkSurface2
                                : AppColors.surfaceContainer,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: isDark
                                ? AppColors.darkSurface2
                                : AppColors.surfaceContainer,
                            child: Icon(
                              Icons.restaurant_outlined,
                              size: 48,
                              color: textSecondary.withValues(alpha: 0.4),
                            ),
                          ),
                        )
                      : Container(
                          color: isDark
                              ? AppColors.darkSurface2
                              : AppColors.surfaceContainer,
                          child: Icon(
                            Icons.restaurant_outlined,
                            size: 48,
                            color: textSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                  // Time badge (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfaceCard.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.cookingTime} min',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Difficulty row
                  Row(
                    children: [
                      Text(
                        recipe.category.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                          letterSpacing: 0.08 * 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('·', style: TextStyle(color: textSecondary)),
                      const SizedBox(width: 6),
                      Text(
                        recipe.difficulty ?? 'Medium',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    recipe.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Ingredient preview
                  Text(
                    recipe.ingredientList.take(4).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: delay, duration: 350.ms)
          .slideY(begin: 0.08, curve: Curves.easeOut),
    );
  }
}

// ── Shimmer loading cards ─────────────────────────────────────────────────────
class _ShimmerCards extends StatelessWidget {
  final bool isDark;
  const _ShimmerCards({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? AppColors.darkSurface2 : AppColors.surfaceContainer;
    final highlightColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(2, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
