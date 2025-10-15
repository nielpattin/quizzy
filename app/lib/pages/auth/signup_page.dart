import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:google_sign_in/google_sign_in.dart" as gs;
import "package:flutter_dotenv/flutter_dotenv.dart";

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'com.quizzy.app://login-callback/',
      );

      // If email confirmation is required, there will be no session.
      final hasSession = res.session != null;

      if (!mounted) return;
      if (hasSession) {
        context.go('/home');
      } else {
        // Navigate to a lightweight confirmation screen
        context.go('/email-confirmation');
      }
    } on AuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user_already_exists':
          case 'email_exists':
            _errorMessage =
                'This email is already registered. Please sign in instead.';
            break;
          case 'email_address_invalid':
          case 'validation_failed':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case 'weak_password':
            _errorMessage =
                'Password is too weak. Please use a stronger password.';
            break;
          case 'signup_disabled':
            _errorMessage = 'Sign ups are currently disabled.';
            break;
          case 'over_request_rate_limit':
            _errorMessage =
                'Too many signup attempts. Please wait a few minutes and try again.';
            break;
          default:
            _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('[SIGNUP] Starting Google sign-up...');
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;
      await gs.GoogleSignIn.instance.initialize(serverClientId: webClientId);

      debugPrint('[SIGNUP] Opening Google authentication...');
      final account = await gs.GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw Exception('No ID token from Google');

      debugPrint('[SIGNUP] Got ID token, signing in with Supabase...');
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      debugPrint('[SIGNUP] Sign-in response received');
      debugPrint(
        '[SIGNUP] Session: ${response.session != null ? "EXISTS" : "NULL"}',
      );
      debugPrint('[SIGNUP] User: ${response.user?.id}');

      if (response.session != null) {
        debugPrint('[SIGNUP] Session successful, waiting 500ms for sync...');
        await Future.delayed(Duration(milliseconds: 500));

        if (mounted) {
          debugPrint('[SIGNUP] Redirecting to /splash for setup check');
          context.go('/splash');
        }
      } else {
        throw Exception('No session returned from Supabase');
      }
    } catch (e, stackTrace) {
      debugPrint('[SIGNUP] Error during Google sign-up: $e');
      debugPrint('[SIGNUP] Stack trace: $stackTrace');
      setState(() {
        if (e.toString().toLowerCase().contains('cancel')) {
          _errorMessage = 'Google sign-up was cancelled.';
        } else if (e.toString().toLowerCase().contains('network')) {
          _errorMessage =
              'Network error. Please check your connection and try again.';
        } else {
          _errorMessage = 'Google sign-up failed. Please try again.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithGitHub() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'com.quizzy.app://login-callback/',
      );
    } catch (e) {
      setState(() {
        if (e.toString().toLowerCase().contains('cancel')) {
          _errorMessage = 'GitHub sign-up was cancelled.';
        } else if (e.toString().toLowerCase().contains('network')) {
          _errorMessage =
              'Network error. Please check your connection and try again.';
        } else {
          _errorMessage = 'GitHub sign-up failed. Please try again.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => context.go("/login"),
                  ),
                  SizedBox(height: 40),
                  Text(
                    "Create Account",
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email.';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _signUpWithEmail();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("or"),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 16),
                  _OAuthButton(
                    icon: Icons.g_mobiledata,
                    label: "Sign up with Google",
                    iconColor: Color(0xFF4285F4),
                    onTap: _isLoading ? null : () => _signUpWithGoogle(),
                  ),
                  SizedBox(height: 12),
                  _OAuthButton(
                    icon: Icons.code,
                    label: "Sign up with GitHub",
                    iconColor: Theme.of(context).colorScheme.onSurface,
                    onTap: _isLoading ? null : () => _signUpWithGitHub(),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? "),
                      InkWell(
                        onTap: () => context.go("/login"),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  const _OAuthButton({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  State<_OAuthButton> createState() => _OAuthButtonState();
}

class _OAuthButtonState extends State<_OAuthButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _isPressed
              ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.7)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: _isPressed
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Row(
            children: [
              Icon(widget.icon, color: widget.iconColor, size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
