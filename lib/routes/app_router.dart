import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/ritual_detail/ritual_detail_screen.dart';
import '../features/ritual_create/ritual_create_screen.dart';
import '../features/rituals/rituals_list_screen.dart';
import '../features/checklist/checklist_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/badges/badges_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/sharing/join_ritual_screen.dart';
import '../features/common/coming_soon_screen.dart';
import '../features/profile/public_profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/edit_profile_screen.dart';
import '../features/premium/screens/premium_screen.dart';
import '../features/help/screens/help_support_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/first_ritual_wizard.dart';

import '../services/api_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final isAuthenticated = ApiService.hasToken;
      final isAuthRoute = state.matchedLocation == '/auth';
      final isWelcomeRoute = state.matchedLocation == '/welcome';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isWizardRoute = state.matchedLocation == '/first-ritual-wizard';

      if (isAuthenticated) {
        if (isAuthRoute || isWelcomeRoute) {
          return '/home';
        }
        return null;
      }

      // Allow access to onboarding routes without auth (they redirect to auth if needed)
      if (isOnboardingRoute || isWizardRoute) {
        return null;
      }

      // If not authenticated and not on an auth/welcome route, go to welcome
      if (!isAuthRoute && !isWelcomeRoute) {
        return '/welcome';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        ),
      ),
      // Onboarding routes
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/first-ritual-wizard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FirstRitualWizard(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
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
        path: '/llm-chat',
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
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/badges',
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/join-ritual',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return JoinRitualScreen(initialCode: code);
        },
      ),
      GoRoute(
        path: '/coming-soon',
        builder: (context, state) => const ComingSoonScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => PublicProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/premium',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PremiumScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
           GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpSupportScreen(),
          ),
        ],
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
    ],
  );
});
