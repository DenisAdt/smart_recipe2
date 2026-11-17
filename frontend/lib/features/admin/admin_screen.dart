import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/models/recipe.dart';
import '../../shared/providers/theme_provider.dart';
import '../../core/api/api_client.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _uploading = false;
  String? _uploadMessage;
  Map<String, dynamic>? _analytics;
  List<Recipe> _recipes = [];
  bool _loadingRecipes = false;
  bool _loadingAnalytics = false;
  int _currentPage = 1;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
    _loadRecipes();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loadingAnalytics = true);
    try {
      final data = await ApiClient.getAnalytics();
      setState(() => _analytics = data);
    } catch (e) {
      // silent
    } finally {
      setState(() => _loadingAnalytics = false);
    }
  }

  Future<void> _loadRecipes({int page = 1}) async {
    setState(() => _loadingRecipes = true);
    try {
      final data = await ApiClient.getRecipes(page: page, pageSize: 30);
      final items = (data['items'] as List<dynamic>? ?? [])
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _recipes = items;
        _currentPage = page;
      });
    } catch (e) {
      // silent
    } finally {
      setState(() => _loadingRecipes = false);
    }
  }

  Future<void> _uploadCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _uploading = true;
      _uploadMessage = null;
    });

    try {
      final response = await ApiClient.uploadCsv(
          file.name, file.bytes!.toList());
      setState(() {
        _uploadMessage =
            '✅ ${response['message'] ?? 'Upload berhasil!'}';
      });
      _loadRecipes();
      _loadAnalytics();
    } catch (e) {
      setState(() {
        _uploadMessage = '❌ Upload gagal: $e';
      });
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _deleteRecipe(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Resep'),
        content: const Text('Yakin ingin menghapus resep ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.deleteRecipe(id);
      _loadRecipes(page: _currentPage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor:
              isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          indicatorColor: AppColors.accentBlue,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Dataset'),
            Tab(text: 'Resep'),
            Tab(text: 'Analitik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDatasetTab(isDark),
          _buildRecipesTab(isDark),
          _buildAnalyticsTab(isDark),
        ],
      ),
    );
  }

  // ── Tab 1: Dataset Upload ─────────────────────────────────
  Widget _buildDatasetTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats overview
          if (_analytics != null) _buildStatsOverview(_analytics!, isDark),
          const SizedBox(height: 24),

          // Upload zone
          GestureDetector(
            onTap: _uploading ? null : _uploadCsv,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.4),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
              ),
              child: Column(
                children: [
                  if (_uploading)
                    const CircularProgressIndicator(color: AppColors.accentBlue)
                  else
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.primaryGradient.createShader(b),
                      child: const Icon(Icons.upload_file_rounded,
                          color: Colors.white, size: 48),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _uploading ? 'Mengupload...' : 'Upload CSV Dataset',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kolom: title, ingredients, instructions, category, cooking_time, difficulty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          if (_uploadMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _uploadMessage!.startsWith('✅')
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _uploadMessage!.startsWith('✅')
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _uploadMessage!,
                style: TextStyle(
                  color: _uploadMessage!.startsWith('✅')
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsOverview(Map<String, dynamic> analytics, bool isDark) {
    final items = [
      {
        'icon': Icons.menu_book_rounded,
        'label': 'Total Resep',
        'value': analytics['total_recipes']
      },
      {
        'icon': Icons.search_rounded,
        'label': 'Total Pencarian',
        'value': analytics['total_searches']
      },
    ];

    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == 0 ? 12 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item['icon'] as IconData,
                    color: AppColors.accentBlue, size: 20),
                const SizedBox(height: 8),
                Text(
                  item['value'].toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Tab 2: Recipes CRUD ────────────────────────────────────
  Widget _buildRecipesTab(bool isDark) {
    if (_loadingRecipes) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = _recipes[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _miniChip(r.category,
                                  AppColors.categoryColor(r.category)),
                              const SizedBox(width: 6),
                              if (r.difficulty != null)
                                _miniChip(
                                    r.difficulty!, AppColors.textTertiary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 20),
                      onPressed: () => _deleteRecipe(r.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Pagination
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _currentPage > 1
                    ? () => _loadRecipes(page: _currentPage - 1)
                    : null,
              ),
              Text('Hal $_currentPage',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  )),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _recipes.length == 30
                    ? () => _loadRecipes(page: _currentPage + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Tab 3: Analytics ───────────────────────────────────────
  Widget _buildAnalyticsTab(bool isDark) {
    if (_loadingAnalytics) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue));
    }

    if (_analytics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined,
                size: 48,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('Belum ada data analitik',
                style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary)),
          ],
        ),
      );
    }

    final topIngredients =
        (_analytics!['top_ingredients'] as List<dynamic>? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top ingredients
          Text(
            '🥬 Bahan Paling Banyak Dicari',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...topIngredients.take(10).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value as Map<String, dynamic>;
            final maxCount = (topIngredients.first as Map)['count'] as int;
            final count = item['count'] as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['ingredient'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: count / maxCount,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? AppColors.darkSurface2
                                : AppColors.surface,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGradient.colors[
                                  i % AppColors.primaryGradient.colors.length],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(duration: 300.ms);
          }),
        ],
      ),
    );
  }
}
