import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "pages/walkthrough_page.dart";
import "pages/get_started_page.dart";
import "pages/login_page.dart";
import "pages/account_type_page.dart";
import "pages/username_page.dart";
import "pages/profile_info_page.dart";
import "pages/main_navigation_page.dart";
import "pages/search_page.dart";
import "pages/notification_page.dart";
import "pages/profile_page.dart";
import "pages/quiz_detail_page.dart";

final router = GoRouter(
  initialLocation: "/walkthrough",
  routes: [
    GoRoute(
      path: "/walkthrough",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WalkthroughPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/get-started",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const GetStartedPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/account-type",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AccountTypePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/username",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const UsernamePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/profile-info",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProfileInfoPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/home",
      builder: (context, state) => const MainNavigationPage(initialIndex: 0),
    ),
    GoRoute(
      path: "/library",
      builder: (context, state) => const MainNavigationPage(initialIndex: 1),
    ),
    GoRoute(
      path: "/join",
      builder: (context, state) => const MainNavigationPage(initialIndex: 2),
    ),
    GoRoute(
      path: "/search",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SearchPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: "/notification",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: "/profile",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProfilePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: "/quiz/:id",
      pageBuilder: (context, state) {
        final quizId = state.pathParameters["id"]!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: QuizDetailPage(quizId: quizId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: "/login",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
  ],
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isOnWalkthrough = state.matchedLocation == "/walkthrough";
    final isOnGetStarted = state.matchedLocation == "/get-started";
    final isOnLogin = state.matchedLocation == "/login";

    if (user != null && (isOnWalkthrough || isOnGetStarted || isOnLogin)) {
      return "/home";
    }

    return null;
  },
);
