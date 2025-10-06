import "package:firebase_auth/firebase_auth.dart";
import "package:go_router/go_router.dart";
import "pages/walkthrough_page.dart";
import "pages/get_started_page.dart";
import "pages/login_page.dart";
import "pages/account_type_page.dart";
import "pages/username_page.dart";
import "pages/profile_info_page.dart";
import "pages/home_page.dart";
import "pages/search_page.dart";
import "pages/notification_page.dart";
import "pages/profile_page.dart";

final router = GoRouter(
  initialLocation: "/walkthrough",
  routes: [
    GoRoute(
      path: "/walkthrough",
      builder: (context, state) => const WalkthroughPage(),
    ),
    GoRoute(
      path: "/get-started",
      builder: (context, state) => const GetStartedPage(),
    ),
    GoRoute(
      path: "/account-type",
      builder: (context, state) => const AccountTypePage(),
    ),
    GoRoute(
      path: "/username",
      builder: (context, state) => const UsernamePage(),
    ),
    GoRoute(
      path: "/profile-info",
      builder: (context, state) => const ProfileInfoPage(),
    ),
    GoRoute(
      path: "/home",
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: "/search",
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: "/notification",
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: "/profile",
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(path: "/login", builder: (context, state) => const LoginPage()),
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
