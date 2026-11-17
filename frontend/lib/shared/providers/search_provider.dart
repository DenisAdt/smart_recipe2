import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_result.dart';
import '../../core/api/api_client.dart';

// ── Ingredients state ──────────────────────────────────────────
final ingredientsProvider =
    StateNotifierProvider<IngredientsNotifier, List<String>>((ref) {
  return IngredientsNotifier();
});

class IngredientsNotifier extends StateNotifier<List<String>> {
  IngredientsNotifier() : super([]);

  void add(String ingredient) {
    final trimmed = ingredient.trim();
    if (trimmed.isNotEmpty && !state.contains(trimmed)) {
      state = [...state, trimmed];
    }
  }

  void remove(String ingredient) {
    state = state.where((e) => e != ingredient).toList();
  }

  void clear() {
    state = [];
  }

  void setAll(List<String> ingredients) {
    state = List<String>.from(ingredients);
  }
}

// ── Algorithm selection ────────────────────────────────────────
//
// Keeps the chosen IR algorithm key separate from post-retrieval
// UI sorting. Changing this triggers a new backend request.
//
// Valid values: "bm25" | "bm25_stem" | "tfidf"
final algorithmProvider = StateProvider<String>((ref) => 'bm25_stem');

/// Human-readable label for each algorithm key.
const Map<String, String> algorithmLabels = {
  'bm25': 'BM25',
  'bm25_stem': 'BM25 + Stemming',
  'tfidf': 'TF-IDF',
};

// ── Search filters ─────────────────────────────────────────────
class SearchFilters {
  final String? category;
  final int? maxCookingTime;
  final String? difficulty;
  const SearchFilters({
    this.category,
    this.maxCookingTime,
    this.difficulty,
  });

  SearchFilters copyWith({
    String? category,
    int? maxCookingTime,
    String? difficulty,
    bool clearCategory = false,
    bool clearTime = false,
    bool clearDifficulty = false,
  }) {
    return SearchFilters(
      category: clearCategory ? null : (category ?? this.category),
      maxCookingTime: clearTime ? null : (maxCookingTime ?? this.maxCookingTime),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
    );
  }
}

final searchFiltersProvider =
    StateNotifierProvider<FiltersNotifier, SearchFilters>((ref) {
  return FiltersNotifier();
});

class FiltersNotifier extends StateNotifier<SearchFilters> {
  FiltersNotifier() : super(const SearchFilters());

  void update(SearchFilters filters) => state = filters;
  void reset() => state = const SearchFilters();
}

// ── Search result state ────────────────────────────────────────
enum SearchStatus { idle, loading, success, error }

class SearchState {
  final SearchStatus status;
  final SearchResponse? response;
  final String? errorMessage;
  final int currentStep;

  const SearchState({
    this.status = SearchStatus.idle,
    this.response,
    this.errorMessage,
    this.currentStep = 0,
  });

  SearchState copyWith({
    SearchStatus? status,
    SearchResponse? response,
    String? errorMessage,
    int? currentStep,
  }) {
    return SearchState(
      status: status ?? this.status,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref);
});

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;

  SearchNotifier(this._ref) : super(const SearchState());

  /// Perform a search using the currently selected algorithm.
  /// Called from the Search screen "Cari Resep" button.
  Future<void> search() async {
    final algorithm = _ref.read(algorithmProvider);
    await searchWithAlgorithm(algorithm);
  }

  /// Re-run search with a specific algorithm key.
  /// Updates [algorithmProvider] so the UI reflects the new selection,
  /// then issues a fresh backend request.
  Future<void> searchWithAlgorithm(String algorithm) async {
    final ingredients = _ref.read(ingredientsProvider);
    final filters = _ref.read(searchFiltersProvider);

    if (ingredients.isEmpty) return;

    // Persist the chosen algorithm for the current session
    _ref.read(algorithmProvider.notifier).state = algorithm;

    state = const SearchState(status: SearchStatus.loading, currentStep: 0);

    // Simulate step-by-step animation (shortened for algorithm switch)
    for (int i = 1; i <= 6; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(currentStep: i);
    }

    try {
      final data = await ApiClient.search(
        ingredients: ingredients,
        category: filters.category,
        maxCookingTime: filters.maxCookingTime,
        difficulty: filters.difficulty,
        algorithm: algorithm,
        topK: 20,
      );
      final response = SearchResponse.fromJson(data);
      state = SearchState(
        status: SearchStatus.success,
        response: response,
        currentStep: 7,
      );
    } catch (e) {
      state = SearchState(
        status: SearchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const SearchState();
  }
}

// ── Autocomplete suggestions ───────────────────────────────────
final suggestionsProvider = FutureProvider.family<List<String>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];
    return ApiClient.getSuggestions(query);
  },
);

