import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "router.dart";
import "theme.dart";

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
  });

  runApp(const QuizzyApp());
}

class QuizzyApp extends StatelessWidget {
  const QuizzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Quizzy",
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: router,
    );
  }
}
