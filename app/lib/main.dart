import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "router.dart";
import "theme.dart";
import "services/in_app_notification_service.dart";
import "services/real_time_notification_service.dart";
import "services/websocket_service.dart";
import "widgets/debug_overlay.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[MAIN] Flutter Error: ${details.exception}');
    debugPrint('[MAIN] Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  debugPrint('[MAIN] Supabase initialized');
  debugPrint('[MAIN] Setting up auth state listener...');

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    final session = data.session;
    debugPrint('[AUTH_LISTENER] Event: $event');
    debugPrint(
      '[AUTH_LISTENER] Session: ${session != null ? "EXISTS (user: ${session.user.id})" : "NULL"}',
    );

    // Only connect on explicit sign-in event, not initialSession
    // This ensures token refresh happens first in splash page
    if (event == AuthChangeEvent.signedIn && session != null) {
      debugPrint(
        '[AUTH_LISTENER] User signed in, initializing real-time services...',
      );
      RealTimeNotificationService().init();
      WebSocketService().connect();
    } else if (event == AuthChangeEvent.initialSession && session != null) {
      debugPrint(
        '[AUTH_LISTENER] Initial session detected, deferring WebSocket connection until after token refresh',
      );
      // Only init notification service, WebSocket will connect after token refresh
      RealTimeNotificationService().init();
    } else if (event == AuthChangeEvent.signedOut) {
      debugPrint('[AUTH_LISTENER] User signed out, disconnecting WebSocket...');
      WebSocketService().disconnect();
    }
  });

  runApp(const QuizzyApp());
}

class QuizzyApp extends StatefulWidget {
  const QuizzyApp({super.key});

  @override
  State<QuizzyApp> createState() => _QuizzyAppState();
}

class _QuizzyAppState extends State<QuizzyApp> {
  final _debugOverlayController = DebugOverlayController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        InAppNotificationService.initialize(context);
      }
    });
  }

  @override
  void dispose() {
    _debugOverlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Quizzy",
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: router,
      builder: (context, child) {
        return DebugOverlay(
          controller: _debugOverlayController,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
