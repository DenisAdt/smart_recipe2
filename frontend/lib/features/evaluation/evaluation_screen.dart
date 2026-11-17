import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/models/evaluation.dart';
import '../../shared/providers/theme_provider.dart';
import '../../core/api/api_client.dart';

// ── Default evaluation queries (academic test set) ──────────
const _defaultQueries = [
  'ayam bawang merah bawang putih',
  'tempe tahu goreng',
  'ikan bawang kunyit',
  'daging sapi kecap',
  'udang cabe terasi',
  'kangkung bawang tempe',
  'telur tomat cabai',
  'santan cabe ayam',
];

// ── Default relevant document IDs per query (ground truth) ──
const Map<String, List<int>> _defaultRelevantIds = {
  'ayam bawang merah bawang putih': [1, 2, 3, 15, 43, 47, 61, 62, 65, 69],
  'tempe tahu goreng': [4, 5, 13, 29, 30, 41, 55, 57, 59, 70],
  'ikan bawang kunyit': [6, 7, 16, 42, 46, 49, 71, 75, 78],
  'daging sapi kecap': [10, 20, 44, 50, 56, 66, 72, 80],
  'udang cabe terasi': [27, 28, 34, 38, 52, 79],
  'kangkung bawang tempe': [21, 30, 38, 59, 82],
  'telur tomat cabai': [58, 67, 68, 76, 83],
  'santan cabe ayam': [15, 19, 20, 22, 36, 46, 48, 62],
};

class EvaluationScreen extends ConsumerStatefulWidget {
  const EvaluationScreen({super.key});

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  bool _isRunning = false;
  EvaluationRunResult? _result;
  String? _error;
  String _selectedAlgo = 'BM25 tanpa Stemming';
  String _selectedComparisonTab = 'F1';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _runEvaluation() async {
    setState(() {
      _isRunning = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await ApiClient.runEvaluation(
        queries: _defaultQueries,
        relevantIds: _defaultRelevantIds,
        kValues: [5, 10],
      );
      if (mounted) {
        setState(() {
          _result = EvaluationRunResult.fromJson(data);
          _isRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRunning = false;
        });
      }
    }
  }

  EvaluationMethodResult? get _bestQuality {
    if (_result == null || _result!.results.isEmpty) return null;
    return _result!.results.reduce((a, b) => a.f1Score > b.f1Score ? a : b);
  }

  EvaluationMethodResult? get _fastest {
    if (_result == null || _result!.results.isEmpty) return null;
    return _result!.results.reduce((a, b) => a.avgQueryTimeMs < b.avgQueryTimeMs ? a : b);
  }

  double _getMetricValue(EvaluationMethodResult r, String tab) {
    switch (tab) {
      case 'Precision':
        return r.precision;
      case 'Recall':
        return r.recall;
      case 'F1':
        return r.f1Score;
      case 'P@5':
        return r.precisionAt5;
      case 'P@10':
        return r.precisionAt10;
      case 'Time':
        return r.avgQueryTimeMs;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
    final inputFill = isDark ? AppColors.darkSurface : AppColors.inputFill;
    final surfaceCard = isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.primaryFixed : AppColors.primary;
    final onPrimaryColor = isDark ? AppColors.inverseSurface : AppColors.onPrimary;
    final accentColor = AppColors.secondary; // Warm Mustard

    final currentResult = _result?.results.firstWhere(
      (r) => r.method == _selectedAlgo,
      orElse: () => _result!.results.first,
    );

    final String pStr = currentResult != null ? currentResult.precision.toStringAsFixed(4) : '—';
    final String rStr = currentResult != null ? currentResult.recall.toStringAsFixed(4) : '—';
    final String f1Str = currentResult != null ? currentResult.f1Score.toStringAsFixed(4) : '—';
    final String p5Str = currentResult != null ? currentResult.precisionAt5.toStringAsFixed(4) : '—';
    final String p10Str = currentResult != null ? currentResult.precisionAt10.toStringAsFixed(4) : '—';
    final String timeStr = currentResult != null ? '${currentResult.avgQueryTimeMs.toStringAsFixed(2)} ms' : '—';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 24, 20, 100 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App Bar ────────────────────────────────────────────
              Text(
                'Search Algorithm Evaluation',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.28,
                  letterSpacing: -0.02 * 28,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Comparison of BM25 and TF-IDF Retrieval Performance',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: textSecondary,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 24),

              // ── Run Button ────────────────────────────────────────
              GestureDetector(
                onTap: _isRunning ? null : _runEvaluation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isRunning ? inputFill : primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRunning)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(textSecondary),
                          ),
                        )
                      else if (_result != null)
                        Icon(Icons.refresh, size: 18, color: onPrimaryColor)
                      else
                        Icon(Icons.play_arrow_outlined, size: 18, color: onPrimaryColor),
                      const SizedBox(width: 8),
                      Text(
                        _isRunning
                            ? 'Running Evaluation...'
                            : (_result != null ? 'Re-run Evaluation' : 'Run Evaluation'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isRunning ? textSecondary : onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  ),
                ),

              // ── Evaluation Summary Card ───────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      icon: Icons.storage_rounded,
                      label: 'Dataset',
                      value: _result != null ? '${_result!.totalRecipesInDataset}' : '—',
                      color: primaryColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _SummaryItem(
                      icon: Icons.search_rounded,
                      label: 'Queries',
                      value: _result != null ? '${_result!.queriesUsed.length}' : '—',
                      color: primaryColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _SummaryItem(
                      icon: Icons.functions_rounded,
                      label: 'Algorithms',
                      value: _result != null ? '${_result!.results.length}' : '—',
                      color: primaryColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    _SummaryItem(
                      icon: _result != null ? Icons.check_circle_rounded : Icons.pending_rounded,
                      label: 'Status',
                      value: _result != null ? 'Completed' : 'Pending',
                      color: _result != null ? AppColors.success : textSecondary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

              const SizedBox(height: 32),

              // ── Algorithm Selector ───────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['BM25 tanpa Stemming', 'BM25 dengan Stemming', 'TF-IDF dengan Stemming'].map((algo) {
                  final isSelected = _selectedAlgo == algo;
                  
                  // Clean up labels for chips
                  String label = algo;
                  if (algo == 'BM25 tanpa Stemming') label = 'BM25';
                  if (algo == 'BM25 dengan Stemming') label = 'BM25 + Stemming';
                  if (algo == 'TF-IDF dengan Stemming') label = 'TF-IDF';

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAlgo = algo),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : inputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? onPrimaryColor : textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 16),
              Text(
                'CURRENT ALGORITHM',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 1.0,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 4),
              Text(
                _selectedAlgo,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 24),

              // ── Performance Metrics ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 350;
                    final itemWidth = isSmall ? constraints.maxWidth / 2 - 16 : constraints.maxWidth / 3 - 24;
                    
                    return Wrap(
                      spacing: isSmall ? 16 : 32,
                      runSpacing: 32,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _MetricValue(
                            label: 'PRECISION',
                            value: pStr,
                            color: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricValue(
                            label: 'RECALL',
                            value: rStr,
                            color: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricValue(
                            label: 'F1 SCORE',
                            value: f1Str,
                            color: primaryColor,
                            textSecondary: textSecondary,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricValue(
                            label: 'PRECISION@5',
                            value: p5Str,
                            color: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricValue(
                            label: 'PRECISION@10',
                            value: p10Str,
                            color: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _MetricValue(
                            label: 'AVG QUERY TIME',
                            value: timeStr,
                            color: accentColor,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

              const SizedBox(height: 32),

              // ── Comparison Section ───────────────────────────────
              Text(
                'Overall Algorithm Comparison',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 8),
              Text(
                'Comparison based on evaluation metrics.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceCard,
                  borderRadius: BorderRadius.circular(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['F1', 'Precision', 'Recall', 'P@5', 'P@10', 'Time'].map((tab) {
                          final isSelected = _selectedComparisonTab == tab;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedComparisonTab = tab),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                tab,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? primaryColor : textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_result != null && _result!.results.isNotEmpty)
                      ..._result!.results.map((r) {
                        final val = _getMetricValue(r, _selectedComparisonTab);
                        
                        final allValues = _result!.results.map((res) => _getMetricValue(res, _selectedComparisonTab));
                        final maxVal = allValues.reduce((a, b) => a > b ? a : b);
                        
                        final displayVal = _selectedComparisonTab == 'Time' 
                            ? '${val.toStringAsFixed(2)} ms' 
                            : val.toStringAsFixed(4);
                            
                        // Clean up label
                        String displayLabel = r.method;
                        if (displayLabel == 'BM25 tanpa Stemming') displayLabel = 'BM25';
                        if (displayLabel == 'BM25 dengan Stemming') displayLabel = 'BM25 + Stemming';
                        if (displayLabel == 'TF-IDF dengan Stemming') displayLabel = 'TF-IDF';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _BarRow(
                            label: displayLabel,
                            value: val,
                            displayValue: displayVal,
                            maxValue: maxVal == 0 ? 1 : maxVal,
                            color: r.method == _selectedAlgo ? primaryColor : textTertiary,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            inputFill: inputFill,
                            isBold: r.method == _selectedAlgo,
                            isLowerBetter: _selectedComparisonTab == 'Time',
                          ),
                        );
                      })
                    else
                      Text('Run evaluation to see comparison.', style: GoogleFonts.inter(color: textSecondary)),
                  ],
                ),
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.05),

              const SizedBox(height: 32),

              // ── Insights Card ────────────────────────────────────
              if (_result != null && _bestQuality != null && _fastest != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withValues(alpha: 0.08), accentColor.withValues(alpha: 0.08)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Best Retrieval Quality',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bestQuality!.method,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Highest Precision, Recall, and F1',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),
                      
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Fastest',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fastest!.method,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Average Query Time: ${_fastest!.avgQueryTimeMs.toStringAsFixed(2)} ms',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.05),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MetricValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textSecondary;

  const _MetricValue({
    required this.label,
    required this.value,
    required this.color,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            letterSpacing: 0.05 * 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.2,
            letterSpacing: -0.01 * 24,
          ),
        ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final double maxValue;
  final Color color;
  final bool isBold;
  final Color textPrimary;
  final Color textSecondary;
  final Color inputFill;
  final bool isLowerBetter;

  const _BarRow({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.maxValue,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputFill,
    this.isBold = false,
    this.isLowerBetter = false,
  });

  @override
  Widget build(BuildContext context) {
    double factor = 0.0;
    if (maxValue > 0) {
      if (isLowerBetter) {
        // For time, the lowest value is the "best", but visually we just want to show proportional magnitude.
        factor = (value / maxValue).clamp(0.0, 1.0);
      } else {
        factor = (value / maxValue).clamp(0.0, 1.0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isBold ? textPrimary : textSecondary,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayValue,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isBold ? textPrimary : textSecondary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: inputFill,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: factor,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, anim, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: anim,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
