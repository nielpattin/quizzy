import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:google_sign_in/google_sign_in.dart" as gs;
import "package:flutter_dotenv/flutter_dotenv.dart";

class AuthModal extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthModal({super.key, this.onAuthSuccess});

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[AUTH_MODAL] Starting Google sign-in...');
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

      if (webClientId == null || webClientId.isEmpty) {
        throw Exception('GOOGLE_WEB_CLIENT_ID not found in .env file');
      }

      debugPrint('[AUTH_MODAL] Client ID: $webClientId');

      // Initialize Google Sign-In with forced sign out to ensure clean state
      await gs.GoogleSignIn.instance.signOut();
      await gs.GoogleSignIn.instance.initialize(serverClientId: webClientId);
      debugPrint('[AUTH_MODAL] Google Sign-In initialized');

      debugPrint('[AUTH_MODAL] Opening Google authentication...');
      final account = await gs.GoogleSignIn.instance.authenticate().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Google Sign-In timed out');
        },
      );
      debugPrint(
        '[AUTH_MODAL] Authentication successful, user: ${account.email}',
      );

      // Get authentication
      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('No ID token from Google');

      debugPrint('[AUTH_MODAL] Got ID token, signing in with Supabase...');
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      debugPrint('[AUTH_MODAL] Sign-in response received');
      debugPrint('[AUTH_MODAL] Full response:');
      debugPrint(
        '  - Session: ${response.session != null ? "EXISTS" : "NULL"}',
      );
      debugPrint('  - User ID: ${response.user?.id}');
      debugPrint('  - User email: ${response.user?.email}');
      debugPrint('  - User metadata: ${response.user?.userMetadata}');
      debugPrint(
        '  - Access token: ${response.session?.accessToken.substring(0, 20)}...',
      );
      debugPrint('  - Session user: ${response.session?.user.id}');

      if (response.session != null) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onAuthSuccess?.call();
        debugPrint('[AUTH_MODAL] Redirecting to /splash for setup check');
        context.go('/splash');
      } else {
        throw Exception('No session returned from Supabase');
      }
    } catch (e, stackTrace) {
      debugPrint('[AUTH_MODAL] Error during Google sign-in: $e');
      debugPrint('[AUTH_MODAL] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGitHub() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('[AUTH_MODAL] Starting GitHub OAuth...');
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'com.quizzy.app://login-callback/',
      );
      debugPrint('[AUTH_MODAL] GitHub OAuth initiated');
    } catch (e, stackTrace) {
      debugPrint('[AUTH_MODAL] Error during GitHub OAuth: $e');
      debugPrint('[AUTH_MODAL] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Create an account to continue",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
          SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          _AuthButton(
            icon: Icons.g_mobiledata,
            label: "Continue with Google",
            iconColor: Color(0xFF4285F4),
            onTap: _isLoading ? null : _signInWithGoogle,
            isLoading: _isLoading,
          ),
          SizedBox(height: 12),
          _AuthButton(
            icon: Icons.code,
            label: "Continue with GitHub",
            iconColor: Theme.of(context).colorScheme.onSurface,
            onTap: _isLoading ? null : _signInWithGitHub,
            isLoading: _isLoading,
          ),
          SizedBox(height: 12),
          _AuthButton(
            icon: Icons.email_outlined,
            label: "Continue with email",
            onTap: _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    context.go("/signup");
                  },
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                        context.go("/login");
                      },
                child: Text(
                  "Log in",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _AuthButton({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showAuthModal(BuildContext context, {VoidCallback? onAuthSuccess}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AuthModal(onAuthSuccess: onAuthSuccess),
  );
}
