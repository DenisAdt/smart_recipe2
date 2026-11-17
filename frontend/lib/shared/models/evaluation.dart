class EvaluationMethodResult {
  final String method;
  final double precision;
  final double recall;
  final double precisionAt5;
  final double precisionAt10;
  final double f1Score;
  final double avgQueryTimeMs;

  const EvaluationMethodResult({
    required this.method,
    required this.precision,
    required this.recall,
    required this.precisionAt5,
    required this.precisionAt10,
    required this.f1Score,
    this.avgQueryTimeMs = 0.0,
  });

  factory EvaluationMethodResult.fromJson(Map<String, dynamic> json) {
    return EvaluationMethodResult(
      method: json['method'] as String,
      precision: (json['precision'] as num).toDouble(),
      recall: (json['recall'] as num).toDouble(),
      precisionAt5: (json['precision_at_5'] as num).toDouble(),
      precisionAt10: (json['precision_at_10'] as num).toDouble(),
      f1Score: (json['f1_score'] as num).toDouble(),
      avgQueryTimeMs: (json['avg_query_time_ms'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get formattedPrecision => '${(precision * 100).toStringAsFixed(1)}%';
  String get formattedRecall => '${(recall * 100).toStringAsFixed(1)}%';
  String get formattedP5 => '${(precisionAt5 * 100).toStringAsFixed(1)}%';
  String get formattedP10 => '${(precisionAt10 * 100).toStringAsFixed(1)}%';
  String get formattedF1 => '${(f1Score * 100).toStringAsFixed(1)}%';
}

class EvaluationRunResult {
  final List<EvaluationMethodResult> results;
  final List<String> queriesUsed;
  final int totalRecipesInDataset;
  final DateTime? timestamp;

  const EvaluationRunResult({
    required this.results,
    required this.queriesUsed,
    this.totalRecipesInDataset = 0,
    this.timestamp,
  });

  factory EvaluationRunResult.fromJson(Map<String, dynamic> json) {
    return EvaluationRunResult(
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => EvaluationMethodResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      queriesUsed: List<String>.from(json['queries_used'] ?? []),
      totalRecipesInDataset: (json['total_recipes_in_dataset'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
    );
  }
}
