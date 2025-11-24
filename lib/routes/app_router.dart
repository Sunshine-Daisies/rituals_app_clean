import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/ritual_detail/ritual_detail_screen.dart';
import '../features/ritual_create/ritual_create_screen.dart';
import '../features/rituals/rituals_list_screen.dart';
import '../features/checklist/checklist_screen.dart';
import '../features/stats/stats_screen.dart';
import '../pages/chat_page.dart';
import '../services/api_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth', // Start with auth page
    redirect: (context, state) {
      final isAuthenticated = ApiService.hasToken;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/rituals',
        builder: (context, state) => const RitualsListScreen(),
      ),
      GoRoute(
        path: '/ritual/create',
        builder: (context, state) => const RitualCreateScreen(),
      ),
      GoRoute(
        path: '/llm-chat',
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: '/ritual/:id',
        builder: (context, state) => RitualDetailScreen(
          ritualId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/checklist/:runId',
        builder: (context, state) => ChecklistScreen(
          runId: state.pathParameters['runId']!,
        ),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatsScreen(),
      ),
    ],
  );
});