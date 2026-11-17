import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/providers/search_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialIngredient;

  const SearchScreen({super.key, this.initialIngredient});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredient != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ingredientsProvider.notifier).add(widget.initialIngredient!);
      });
    }
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() async {
    final query = _textController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    try {
      final sugg = await ref.read(suggestionsProvider(query).future);
      if (mounted) {
        setState(() {
          _suggestions = sugg;
          _showSuggestions = sugg.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  void _addIngredient(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      ref.read(ingredientsProvider.notifier).add(trimmed);
      _textController.clear();
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _doSearch() async {
    final ingredients = ref.read(ingredientsProvider);
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tambahkan minimal 1 bahan terlebih dahulu!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SearchLoadingDialog(),
    );

    await ref.read(searchProvider.notifier).search();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close dialog

    final searchState = ref.read(searchProvider);
    if (searchState.status == SearchStatus.success && searchState.response != null) {
      context.go('/results', extra: {
        'ingredients': ingredients,
        'results': searchState.response!.results,
        'totalFound': searchState.response!.totalFound,
      });
    } else if (searchState.status == SearchStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(searchState.errorMessage ?? 'Terjadi kesalahan'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final ingredients = ref.watch(ingredientsProvider);

    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final inputFill = isDark ? AppColors.darkSurface : AppColors.inputFill;
    final surfaceCard = isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.primaryFixed : AppColors.primary;
    final onPrimaryColor = isDark ? AppColors.inverseSurface : AppColors.onPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                200 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────
                  Text(
                    'Apa yang ada di kulkasmu?',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      height: 1.28,
                      letterSpacing: -0.02 * 28,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih bahan yang kamu punya, kami akan carikan resepnya.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // ── Search input ─────────────────────────────
                  Column(
                    children: [
                      SearchBar(
                        controller: _textController,
                        focusNode: _focusNode,
                        backgroundColor: WidgetStatePropertyAll(inputFill),
                        elevation: const WidgetStatePropertyAll(0),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _focusNode.hasFocus
                                ? BorderSide(color: primaryColor, width: 2)
                                : BorderSide.none,
                          ),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16),
                        ),
                        hintText: 'Cari bahan (cth: Ayam, Bawang Merah...)',
                        hintStyle: WidgetStatePropertyAll(
                          GoogleFonts.inter(
                            fontSize: 16,
                            color: textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                        textStyle: WidgetStatePropertyAll(
                          GoogleFonts.inter(
                            fontSize: 16,
                            color: textPrimary,
                          ),
                        ),
                        leading: Icon(Icons.search, color: textSecondary, size: 22),
                        trailing: [
                          if (_textController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.close, size: 20, color: textSecondary),
                              onPressed: () {
                                _textController.clear();
                                setState(() {
                                  _suggestions = [];
                                  _showSuggestions = false;
                                });
                              },
                            ),
                        ],
                        onSubmitted: _addIngredient,
                      ),
                      // ── Autocomplete suggestions ─────────────
                      if (_showSuggestions)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 250),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: _suggestions.take(8).map((s) {
                              return InkWell(
                                onTap: () => _addIngredient(s),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 18,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          s,
                                          maxLines: 2,
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 120.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  // ── Selected ingredients ─────────────────────
                  if (ingredients.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'Bahan Terpilih (${ingredients.length})',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              ref.read(ingredientsProvider.notifier).clear(),
                          child: Text(
                            'Hapus Semua',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ingredients.map((ing) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ing,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: onPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => ref
                                    .read(ingredientsProvider.notifier)
                                    .remove(ing),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: onPrimaryColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Popular Ingredients ──────────────────────
                  Text(
                    'Bahan Populer',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.quickIngredients.map((ing) {
                      final isSelected = ingredients.contains(ing);
                      return GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            ref
                                .read(ingredientsProvider.notifier)
                                .remove(ing);
                          } else {
                            ref.read(ingredientsProvider.notifier).add(ing);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : inputFill,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ing,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? onPrimaryColor : textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ),
            ),
          ),

          // ── Fixed bottom search button ────────────────────────
          Positioned(
            bottom: 90 + MediaQuery.of(context).padding.bottom,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: _doSearch,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: ingredients.isEmpty
                      ? (isDark ? AppColors.darkSurface2 : AppColors.surfaceContainer)
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: ingredients.isNotEmpty
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Cari Resep',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ingredients.isEmpty
                          ? textSecondary
                          : AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading dialog ─────────────────────────────────────────────────────────────
class _SearchLoadingDialog extends ConsumerWidget {
  const _SearchLoadingDialog();

  static const List<String> _steps = [
    'Memproses bahan...',
    'Menjalankan BM25...',
    'Menghitung skor relevansi...',
    'Menyusun hasil pencarian...',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final searchState = ref.watch(searchProvider);
    final step = searchState.currentStep.clamp(0, _steps.length - 1);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.primaryFixed : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _steps[step],
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mencari resep terbaik untukmu...',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
