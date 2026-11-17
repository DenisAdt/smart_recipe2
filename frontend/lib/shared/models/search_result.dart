class SearchResult {
  final int recipeId;
  final String title;
  final String category;
  final String? imageUrl;
  final int? cookingTime;
  final String? difficulty;
  final double bm25Score;
  final double matchPercentage;
  final List<String> matchedIngredients;
  final List<String> missingIngredients;
  final int matchedCount;
  final int totalQueryCount;
  final int rank;
  final int relevanceStars;
  final String relevanceLabel;

  const SearchResult({
    required this.recipeId,
    required this.title,
    required this.category,
    this.imageUrl,
    this.cookingTime,
    this.difficulty,
    required this.bm25Score,
    required this.matchPercentage,
    required this.matchedIngredients,
    required this.missingIngredients,
    required this.matchedCount,
    required this.totalQueryCount,
    required this.rank,
    required this.relevanceStars,
    required this.relevanceLabel,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      recipeId: json['recipe_id'] as int,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'Goreng',
      imageUrl: json['image_url'] as String?,
      cookingTime: json['cooking_time'] as int?,
      difficulty: json['difficulty'] as String?,
      bm25Score: (json['bm25_score'] as num).toDouble(),
      matchPercentage: (json['match_percentage'] as num).toDouble(),
      matchedIngredients: List<String>.from(json['matched_ingredients'] ?? []),
      missingIngredients: List<String>.from(json['missing_ingredients'] ?? []),
      matchedCount: json['matched_count'] as int? ?? 0,
      totalQueryCount: json['total_query_count'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      relevanceStars: json['relevance_stars'] as int? ?? 1,
      relevanceLabel: json['relevance_label'] as String? ?? 'Low',
    );
  }

  String get formattedScore => bm25Score.toStringAsFixed(4);
  String get formattedMatch => '${matchPercentage.toStringAsFixed(0)}%';
  String get matchSummary => '$matchedCount/$totalQueryCount Bahan Cocok';
}

class SearchResponse {
  final String query;
  final List<String> ingredients;
  final int totalFound;
  final List<SearchResult> results;
  final List<String> processingSteps;
  /// Which IR algorithm produced these results: "bm25" | "bm25_stem" | "tfidf"
  final String algorithmUsed;

  const SearchResponse({
    required this.query,
    required this.ingredients,
    required this.totalFound,
    required this.results,
    required this.processingSteps,
    this.algorithmUsed = 'bm25_stem',
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query'] as String? ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      totalFound: json['total_found'] as int? ?? 0,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      processingSteps: List<String>.from(json['processing_steps'] ?? []),
      algorithmUsed: json['algorithm_used'] as String? ?? 'bm25_stem',
    );
  }
}

