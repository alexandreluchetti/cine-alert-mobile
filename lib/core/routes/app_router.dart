import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/search/search_results_screen.dart';
import '../../presentation/screens/detail/title_detail_screen.dart';
import '../../presentation/screens/reminders/reminders_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/main/main_shell.dart';
import '../network/session_notifier.dart';

const _publicRoutes = ['/splash', '/login', '/register'];

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    // Escuta tanto expiração de sessão quanto mudanças de login/logout.
    refreshListenable: Listenable.merge([
      SessionNotifier.instance,
      AuthStateNotifier.instance,
    ]),
    redirect: (context, state) {
      final isExpired = SessionNotifier.instance.isSessionExpired;
      final isAuthenticated = AuthStateNotifier.instance.isAuthenticated;
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      // Redireciona para login se não autenticado ou com sessão expirada,
      // exceto em rotas públicas (splash, login, register).
      if ((!isAuthenticated || isExpired) && !isPublic) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
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
              final query = state.uri.queryParameters['q'];
              return SearchResultsScreen(initialQuery: query);
            },
          ),
          GoRoute(
            path: '/reminders',
            name: 'reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/detail/:imdbId',
        name: 'detail',
        pageBuilder: (context, state) {
          final imdbId = state.pathParameters['imdbId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: TitleDetailScreen(imdbId: imdbId, heroData: extra),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
    ],
  );
});
