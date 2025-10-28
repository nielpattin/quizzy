import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "dart:convert";
import "dart:async";
import "../../services/websocket_service.dart";

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _checkUserStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Session?> _refreshSessionIfNeeded(Session session) async {
    try {
      final expiresAt = session.expiresAt;
      if (expiresAt == null) return session;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final timeUntilExpiry = expiresAt - now;

      if (timeUntilExpiry < 300) {
        debugPrint('[SPLASH] Token expires soon, refreshing...');
        final response = await Supabase.instance.client.auth.refreshSession();
        if (response.session != null) {
          debugPrint('[SPLASH] Token refreshed successfully');

          // Reconnect WebSocket with fresh token
          try {
            debugPrint('[SPLASH] Reconnecting WebSocket with fresh token...');
            await WebSocketService().disconnect();
            await Future.delayed(Duration(milliseconds: 100));
            await WebSocketService().connect();
            debugPrint('[SPLASH] WebSocket reconnected');
          } catch (wsError) {
            // Log but don't crash - WebSocket will auto-reconnect
            debugPrint(
              '[SPLASH] WebSocket reconnection failed (will auto-retry): $wsError',
            );
          }

          return response.session;
        }
      }
      return session;
    } catch (e) {
      debugPrint('[SPLASH] Token refresh failed: $e');
      return null;
    }
  }

  Future<void> _checkUserStatus() async {
    final startTime = DateTime.now();
    debugPrint('[SPLASH] Starting user status check');

    try {
      debugPrint('[SPLASH] Checking current session...');
      var session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        debugPrint(
          '[SPLASH] No immediate session, waiting for auth state change...',
        );

        final completer = Completer<Session?>();
        late final StreamSubscription subscription;

        subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
          data,
        ) {
          if (data.event == AuthChangeEvent.signedIn && data.session != null) {
            debugPrint('[SPLASH] Auth state changed to signedIn');
            completer.complete(data.session);
            subscription.cancel();
          }
        });

        final timeoutTimer = Timer(Duration(milliseconds: 3000), () {
          debugPrint('[SPLASH] Timeout waiting for auth state change');
          if (!completer.isCompleted) {
            completer.complete(null);
            subscription.cancel();
          }
        });

        session = await completer.future;
        timeoutTimer.cancel();
      }

      if (session != null) {
        session = await _refreshSessionIfNeeded(session);

        if (session == null) {
          debugPrint('[SPLASH] Session refresh failed, signing out...');
          await Supabase.instance.client.auth.signOut();
          await _ensureMinimumDelay(startTime);
          if (mounted) {
            context.go("/welcome");
          }
          return;
        }

        debugPrint('[SPLASH] Session valid! User ID: ${session.user.id}');
        final token = session.accessToken;
        final serverUrl = dotenv.env["SERVER_URL"]!;

        debugPrint(
          '[SPLASH] Fetching user profile from: $serverUrl/api/user/profile',
        );

        try {
          final response = await http
              .get(
                Uri.parse("$serverUrl/api/user/profile"),
                headers: {"Authorization": "Bearer $token"},
              )
              .timeout(
                Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException(
                    'Profile fetch timed out after 10 seconds',
                  );
                },
              );

          debugPrint(
            '[SPLASH] Profile response status: ${response.statusCode}',
          );
          debugPrint('[SPLASH] Profile response body: ${response.body}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            debugPrint('[SPLASH] Parsed data: $data');

            final isSetupComplete = data["isSetupComplete"] ?? false;
            final email = data["email"];
            final fullName = data["fullName"];
            final username = data["username"];

            debugPrint('[SPLASH] User details:');
            debugPrint('   - Email: $email');
            debugPrint('   - Full Name: $fullName');
            debugPrint('   - Username: $username');
            debugPrint('   - isSetupComplete: $isSetupComplete');

            await _ensureMinimumDelay(startTime);

            if (mounted) {
              if (!isSetupComplete) {
                debugPrint(
                  '[SPLASH] Setup NOT complete, redirecting to /setup-account',
                );
                context.go("/setup-account");
              } else {
                debugPrint('[SPLASH] Setup complete, redirecting to /home');
                context.go("/home");
              }
            }
            return;
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            debugPrint(
              '[SPLASH] Auth error (${response.statusCode}), signing out...',
            );
            await Supabase.instance.client.auth.signOut();
            await _ensureMinimumDelay(startTime);
            if (mounted) {
              context.go("/welcome");
            }
            return;
          } else if (response.statusCode == 404) {
            debugPrint(
              '[SPLASH] User profile not found (404), this should not happen anymore!',
            );
            debugPrint('[SPLASH] Response body: ${response.body}');
            await _ensureMinimumDelay(startTime);
            if (mounted) {
              context.go("/setup-account");
            }
            return;
          } else {
            debugPrint('[SPLASH] Unexpected response: ${response.statusCode}');
            debugPrint('[SPLASH] Response body: ${response.body}');
            await Supabase.instance.client.auth.signOut();
            await _ensureMinimumDelay(startTime);
            if (mounted) {
              context.go("/welcome");
            }
            return;
          }
        } catch (httpError) {
          debugPrint('[SPLASH] HTTP request error: $httpError');
          await Supabase.instance.client.auth.signOut();
          await _ensureMinimumDelay(startTime);
          if (mounted) {
            context.go("/welcome");
          }
          return;
        }
      } else {
        debugPrint('[SPLASH] No session found');
      }
    } catch (e, stackTrace) {
      debugPrint('[SPLASH] Error checking user status: $e');
      debugPrint('[SPLASH] Stack trace: $stackTrace');
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (signOutError) {
        debugPrint('[SPLASH] Error during sign out: $signOutError');
      }
    }

    await _ensureMinimumDelay(startTime);

    if (mounted) {
      debugPrint('[SPLASH] No valid session, redirecting to /welcome');
      context.go("/welcome");
    }
  }

  Future<void> _ensureMinimumDelay(DateTime startTime) async {
    const minDelay = Duration(seconds: 2);
    final elapsed = DateTime.now().difference(startTime);
    final remaining = minDelay - elapsed;

    if (remaining.inMilliseconds > 0) {
      await Future.delayed(remaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("images/Logo.png", width: 120, height: 120),
                SizedBox(height: 24),
                Text(
                  "Quizzy",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 48),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
