import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// API base URL — dynamically uses localhost or 10.0.2.2 based on platform
class AppConstants {
  AppConstants._();

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static String get apiUrl => '$baseUrl/api';

  // Quick ingredient chips on Home screen
  static const List<String> quickIngredients = [
    'Ayam',
    'Telur',
    'Tempe',
    'Tahu',
    'Cabai',
    'Tomat',
    'Kentang',
    'Bawang',
    'Udang',
    'Daging Sapi',
    'Ikan',
    'Kangkung',
  ];

  // Category options
  static const List<String> categories = [
    'Semua',
    'Goreng',
    'Rebus',
    'Tumis',
    'Panggang',
  ];

  // Difficulty options
  static const List<String> difficulties = ['Semua', 'Easy', 'Medium', 'Hard'];

  // Cooking time filters (minutes)
  static const List<Map<String, dynamic>> cookingTimeFilters = [
    {'label': 'Semua', 'value': null},
    {'label': '< 15 menit', 'value': 15},
    {'label': '< 30 menit', 'value': 30},
    {'label': '< 60 menit', 'value': 60},
  ];

  // Relevance badge labels
  static const Map<int, String> relevanceLabels = {
    5: 'Highly Relevant',
    4: 'Relevant',
    3: 'Moderate',
    2: 'Partial Match',
    1: 'Low Match',
  };
}
