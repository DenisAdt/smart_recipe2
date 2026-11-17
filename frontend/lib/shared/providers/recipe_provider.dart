import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../../core/api/api_client.dart';

// ── Stats ──────────────────────────────────────────────────────
final statsProvider = FutureProvider<DatasetStats>((ref) async {
  final data = await ApiClient.getStats();
  return DatasetStats.fromJson(data);
});

// ── Popular Recipes ─────────────────────────────────────────────
final popularRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final data = await ApiClient.getPopularRecipes(limit: 10);
  return data.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Recipe Detail ──────────────────────────────────────────────
final recipeDetailProvider = FutureProvider.family<Recipe, int>((ref, id) async {
  final data = await ApiClient.getRecipe(id);
  return Recipe.fromJson(data);
});

// ── Recipes List ───────────────────────────────────────────────
final recipesProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, params) async {
    return ApiClient.getRecipes(
      page: params['page'] as int? ?? 1,
      pageSize: params['pageSize'] as int? ?? 20,
      category: params['category'] as String?,
    );
  },
);
