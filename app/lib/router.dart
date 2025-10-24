import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "pages/common/splash_page.dart";
import "pages/common/notification_page.dart";
import "pages/auth/welcome_page.dart";
import "pages/auth/login_page.dart";
import "pages/auth/signup_page.dart";
import "pages/auth/forgot_password_page.dart";
import "pages/auth/email_confirmation_page.dart";
import "pages/auth/setup_account_page.dart";
import "pages/home/main_navigation_page.dart";

import "pages/profile/profile_info_page.dart";
import "pages/profile/profile_page.dart";
import "pages/profile/user_profile_page.dart";
import "pages/profile/settings_page.dart";
import "pages/profile/edit_profile_page.dart";
import "pages/social/search_page.dart";
import "pages/social/post_details_page.dart";
import "pages/social/create_post_page.dart";
import "pages/social/create_quiz_post_page.dart";
import "pages/quiz/quiz_detail_page.dart";
import "pages/quiz/category_page.dart";
import "pages/quiz/trending_page.dart";
import "pages/quiz/continue_playing_page.dart";
import "pages/quiz/create_quiz_page.dart";
import "pages/quiz/edit_quiz_page.dart";
import "pages/quiz/add_questions_page.dart";
import "pages/quiz/play_quiz_page.dart";
import "pages/quiz/create_question_page.dart";
import "pages/session/live_quiz_session_page.dart";
import "utils/route_observer.dart";

final router = GoRouter(
  initialLocation: "/",
  observers: [NavigationObserver()],
  routes: [
    GoRoute(
      path: "/",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/splash",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/welcome",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WelcomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/setup-account",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SetupAccountPage(),
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
      path: "/create-post",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CreatePostPage(),
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
      path: "/create-post/quiz",
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const CreateQuizPostPage(),
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
      path: "/post/details",
      pageBuilder: (context, state) {
        final postId = state.extra as String;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PostDetailsPage(postId: postId),
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
      path: "/profile/:id",
      pageBuilder: (context, state) {
        final userId = state.pathParameters["id"]!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: UserProfilePage(userId: userId),
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
      path: "/category/:name",
      pageBuilder: (context, state) {
        final categoryName = state.pathParameters["name"]!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CategoryPage(category: categoryName),
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
      path: "/trending",
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const TrendingPage(),
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
      path: "/edit-profile",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EditProfilePage(),
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
      path: "/continue-playing",
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const ContinuePlayingPage(),
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
      path: "/create-quiz",
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const CreateQuizPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
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
      path: "/quiz/:id/add-questions",
      pageBuilder: (context, state) {
        final quizId = state.pathParameters["id"]!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: AddQuestionsPage(quizId: quizId),
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
      path: "/quiz/:id/edit",
      pageBuilder: (context, state) {
        final quizId = state.pathParameters["id"]!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: EditQuizPage(quizId: quizId),
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
      path: "/quiz/:id/create-question",
      pageBuilder: (context, state) {
        final quizId = state.pathParameters["id"]!;
        final questionType =
            state.uri.queryParameters["type"] ?? "multiple_choice";
        final existingQuestion = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: CreateQuestionPage(
            quizId: quizId,
            questionType: questionType,
            existingQuestion: existingQuestion,
          ),
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
      path: "/quiz/:id/play",
      pageBuilder: (context, state) {
        final quizId = state.pathParameters["id"]!;
        final isPreview = state.uri.queryParameters["preview"] == "true";
        return CustomTransitionPage(
          key: state.pageKey,
          child: PlayQuizPage(quizId: quizId, isPreview: isPreview),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: "/quiz/session/live/:sessionId",
      pageBuilder: (context, state) {
        final sessionId = state.pathParameters["sessionId"]!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: LiveQuizSessionPage(sessionId: sessionId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
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
    GoRoute(
      path: "/signup",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignupPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/email-confirmation",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const EmailConfirmationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/forgot-password",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ForgotPasswordPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: "/settings",
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsPage(),
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
  ],
);
