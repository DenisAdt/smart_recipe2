import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

class ApiClient {
  ApiClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
      _RetryInterceptor(),
    ]);

  static Dio get instance => _dio;

  // ── Search ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> search({
    required List<String> ingredients,
    String? category,
    int? maxCookingTime,
    String? difficulty,
    String algorithm = 'bm25_stem',
    int topK = 20,
  }) async {
    final response = await _dio.post('/search', data: {
      'ingredients': ingredients,
      'filters': {
        if (category != null && category != 'Semua') 'category': category,
        if (maxCookingTime != null) 'max_cooking_time': maxCookingTime,
        if (difficulty != null && difficulty != 'Semua') 'difficulty': difficulty,
        'algorithm': algorithm,
      },
      'top_k': topK,
    });
    return response.data as Map<String, dynamic>;
  }

  // ── Recipes ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getRecipes({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? search,
  }) async {
    final response = await _dio.get('/recipes', queryParameters: {
      'page': page,
      'page_size': pageSize,
      if (category != null && category != 'Semua') 'category': category,
      if (search != null) 'search': search,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRecipe(int id) async {
    final response = await _dio.get('/recipes/$id');
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPopularRecipes({int limit = 10}) async {
    final response = await _dio.get('/recipes/popular', queryParameters: {'limit': limit});
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/stats');
    return response.data as Map<String, dynamic>;
  }

  // ── Suggestions ────────────────────────────────────────────
  static Future<List<String>> getSuggestions(String query) async {
    final response = await _dio.get('/search/suggestions', queryParameters: {'q': query});
    final data = response.data as Map<String, dynamic>;
    return List<String>.from(data['suggestions'] ?? []);
  }

  // ── Evaluation ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> runEvaluation({
    required List<String> queries,
    required Map<String, List<int>> relevantIds,
    List<int> kValues = const [5, 10],
  }) async {
    final response = await _dio.post('/evaluation/run', data: {
      'queries': queries,
      'relevant_recipe_ids': relevantIds,
      'k_values': kValues,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getEvaluationResults() async {
    final response = await _dio.get('/evaluation/results');
    return response.data as List<dynamic>;
  }

  // ── Admin ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _dio.get('/admin/analytics');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadCsv(String filePath, List<int> fileBytes) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: 'recipes.csv'),
    });
    final response = await _dio.post('/admin/upload', data: formData);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteRecipe(int id) async {
    await _dio.delete('/admin/recipes/$id');
  }
}

/// Simple retry interceptor for transient errors
class _RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          message: 'Koneksi timeout. Pastikan backend berjalan di port 8000.',
        ),
      );
      return;
    }
    handler.next(err);
  }
}
