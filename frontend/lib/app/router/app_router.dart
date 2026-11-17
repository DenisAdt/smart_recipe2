import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/detail/detail_screen.dart';
import '../../features/evaluation/evaluation_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/my_recipes/my_recipes_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../shared/widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Splash (no nav bar) ──────────────────────────────────────
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Main shell with floating nav bar ─────────────────────────
    // Bottom nav: Home | Search | Evaluation | Profile
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) {
            final ingredient = state.uri.queryParameters['ingredient'];
            return SearchScreen(initialIngredient: ingredient);
          },
        ),
        // Evaluation is now a primary nav tab (replaces My Recipes in shell)
        GoRoute(
          path: '/evaluation',
          name: 'evaluation',
          builder: (context, state) => const EvaluationScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        // My Recipes accessible from Profile menu (not in bottom nav)
        GoRoute(
          path: '/my-recipes',
          name: 'my-recipes',
          builder: (context, state) => const MyRecipesScreen(),
        ),
      ],
    ),

    // ── Detail & Results (no persistent nav, back-navigation flows) ──
    GoRoute(
      path: '/results',
      name: 'results',
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(
      path: '/detail/:id',
      name: 'detail',
      builder: (context, state) {
        final recipeId = int.parse(state.pathParameters['id'] ?? '0');
        final extra = state.extra as Map<String, dynamic>?;
        return DetailScreen(
          recipeId: recipeId,
          searchResult: extra?['searchResult'],
        );
      },
    ),

    // ── Admin (no nav bar) ──────────────────────────────────────
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminScreen(),
    ),
  ],
);
