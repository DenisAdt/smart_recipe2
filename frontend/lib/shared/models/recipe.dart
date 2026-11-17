class Recipe {
  final int id;
  final String title;
  final String ingredients;
  final String instructions;
  final String category;
  final String? imageUrl;
  final int? cookingTime;
  final String? difficulty;
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.category,
    this.imageUrl,
    this.cookingTime,
    this.difficulty,
    this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['title'] as String,
      ingredients: json['ingredients'] as String,
      instructions: json['instructions'] as String,
      category: json['category'] as String? ?? 'Goreng',
      imageUrl: json['image_url'] as String?,
      cookingTime: json['cooking_time'] as int?,
      difficulty: json['difficulty'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  List<String> get ingredientList {
    return ingredients
        .split(RegExp(r'--|[,\n;|]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> get instructionSteps {
    // Split by numbered steps or newlines
    final lines = instructions
        .split(RegExp(r'\.\s+(?=[A-Z])|(?<=\.)\s*\n'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return lines.isEmpty ? [instructions] : lines;
  }
}

class DatasetStats {
  final int totalRecipes;
  final int uniqueIngredients;
  final int totalSearches;
  final Map<String, int> categories;

  const DatasetStats({
    required this.totalRecipes,
    required this.uniqueIngredients,
    required this.totalSearches,
    required this.categories,
  });

  factory DatasetStats.fromJson(Map<String, dynamic> json) {
    return DatasetStats(
      totalRecipes: json['total_recipes'] as int? ?? 0,
      uniqueIngredients: json['unique_ingredients'] as int? ?? 0,
      totalSearches: json['total_searches'] as int? ?? 0,
      categories: Map<String, int>.from(json['categories'] as Map? ?? {}),
    );
  }
}
