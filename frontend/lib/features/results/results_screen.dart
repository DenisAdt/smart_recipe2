import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/search_result.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/search_provider.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String _selectedCategory = 'Semua';
  List<SearchResult> _filteredResults = [];

  @override
  void initState() {
    super.initState();
  }

  void _applyFilter() {
    setState(() {}); // trigger rebuild
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final searchState = ref.watch(searchProvider);
    final userIngredients = ref.watch(ingredientsProvider);
    final selectedAlgorithm = ref.watch(algorithmProvider);

    var results = searchState.response?.results.cast<SearchResult>().toList() ?? [];
    if (_selectedCategory != 'Semua') {
      results = results.where((r) => r.category == _selectedCategory).toList();
    }
    _filteredResults = results;

    final totalFound = searchState.response?.totalFound ?? 0;
    final algorithmUsed = searchState.response?.algorithmUsed ?? selectedAlgorithm;

    // Score label changes per algorithm
    final scoreLabel = switch (algorithmUsed) {
      'tfidf'    => 'TF-IDF',
      'bm25'     => 'BM25',
      _          => 'BM25',
    };

    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final inputFill = isDark ? AppColors.darkSurface : AppColors.inputFill;
    final surfaceCard = isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.primaryFixed : AppColors.primary;

    final isLoading = searchState.status == SearchStatus.loading;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => context.go('/search'),
        ),
        title: Text(
          'Hasil Pencarian',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Algorithm selector ──────────────────────────────
            _AlgorithmSelector(
              selected: selectedAlgorithm,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              inputFill: inputFill,
              primaryColor: primaryColor,
              onSelect: (key) {
                if (key != selectedAlgorithm && !isLoading) {
                  ref.read(searchProvider.notifier).searchWithAlgorithm(key);
                }
              },
            ),

            // ── Ingredient chips header ─────────────────────────
            if (userIngredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: userIngredients.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          userIngredients[i],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ── Results count ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                '$totalFound matching recipes found',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),

            // ── Category filter chips ───────────────────────────
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: AppConstants.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = AppConstants.categories[i];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _applyFilter();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : inputFill,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? (isDark
                                  ? AppColors.inverseSurface
                                  : AppColors.onPrimary)
                              : textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Recipe cards list / Loading overlay ─────────────
            Expanded(
              child: isLoading
                  ? _AlgorithmLoadingIndicator(
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      primaryColor: primaryColor,
                      algorithmKey: selectedAlgorithm,
                    )
                  : _filteredResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 56,
                                  color: textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada resep ditemukan',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            100 + MediaQuery.of(context).padding.bottom,
                          ),
                          itemCount: _filteredResults.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _ResultCard(
                              result: _filteredResults[index],
                              isDark: isDark,
                              surfaceCard: surfaceCard,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              inputFill: inputFill,
                              scoreLabel: scoreLabel,
                              delay: (index * 40).ms,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Algorithm selector row ─────────────────────────────────────
class _AlgorithmSelector extends StatelessWidget {
  final String selected;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color inputFill;
  final Color primaryColor;
  final void Function(String key) onSelect;

  const _AlgorithmSelector({
    required this.selected,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputFill,
    required this.primaryColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Algorithm',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: algorithmLabels.entries.map((entry) {
                final isSelected = selected == entry.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect(entry.key),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected) ...[
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: isDark ? AppColors.inverseSurface : AppColors.onPrimary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? AppColors.inverseSurface : AppColors.onPrimary)
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Switch algorithm to compare search results.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Algorithm loading indicator ────────────────────────────────
class _AlgorithmLoadingIndicator extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final String algorithmKey;

  const _AlgorithmLoadingIndicator({
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.algorithmKey,
  });

  @override
  Widget build(BuildContext context) {
    final label = algorithmLabels[algorithmKey] ?? algorithmKey;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Menjalankan $label...',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Memperbarui peringkat resep',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


// ── Result card ───────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final SearchResult result;
  final bool isDark;
  final Color surfaceCard;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color inputFill;
  /// Abbreviation of the active IR algorithm shown in the score footer.
  final String scoreLabel;
  final Duration delay;

  const _ResultCard({
    required this.result,
    required this.isDark,
    required this.surfaceCard,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputFill,
    this.scoreLabel = 'BM25',
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final matchPct = result.matchPercentage;
    // High match (≥70%) → primary-container badge, lower → surface badge
    final isHighMatch = matchPct >= 70;
    final badgeBg = isHighMatch
        ? (isDark ? AppColors.primaryContainer : AppColors.primaryContainer)
        : (isDark ? AppColors.darkSurface2 : AppColors.surfaceContainer);
    final badgeText = isHighMatch
        ? AppColors.onPrimaryContainer
        : textSecondary;

    return GestureDetector(
      onTap: () {
        context.go(
          '/detail/${result.recipeId}',
          extra: {'searchResult': result},
        );
      },
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
            // ── Image with rank badge ──────────────────────────
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (result.imageUrl != null && result.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: result.imageUrl!,
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
                              color: textSecondary.withValues(alpha: 0.3),
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
                            color: textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                  // Rank badge (top left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface.withValues(alpha: 0.85)
                            : AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '#${result.rank}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Card content ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + match badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          result.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isHighMatch) ...[
                              const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: AppColors.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              result.formattedMatch,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: badgeText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Time + Difficulty
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined,
                          size: 15, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${result.cookingTime ?? "?"}m',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textSecondary.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.signal_cellular_alt_outlined,
                          size: 15, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        result.difficulty ?? 'Medium',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Matched ingredient chips
                  if (result.matchedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...result.matchedIngredients.take(3).map((ing) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ing,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textPrimary,
                              ),
                            ),
                          );
                        }),
                        if (result.matchedIngredients.length > 3)
                          Text(
                            '+${result.matchedIngredients.length - 3} more',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // BM25 score footer
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$scoreLabel SCORE: ${result.formattedScore}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textSecondary.withValues(alpha: 0.5),
                            letterSpacing: 0.08 * 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: delay, duration: 300.ms)
          .slideY(begin: 0.06, curve: Curves.easeOut),
    );
  }
}
