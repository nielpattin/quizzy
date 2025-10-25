import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "dart:convert";

class SetupAccountPage extends StatefulWidget {
  final String? email;
  final String? name;
  final String? image;

  const SetupAccountPage({super.key, this.email, this.name, this.image});

  @override
  State<SetupAccountPage> createState() => _SetupAccountPageState();
}

class _SetupAccountPageState extends State<SetupAccountPage> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();

  void _debugPrintSession(String context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      debugPrint('=== SESSION DEBUG ($context) ===');
      debugPrint('Access Token: ${session.accessToken}');
      debugPrint('Refresh Token: ${session.refreshToken}');
      debugPrint('User ID: ${session.user.id}');
      debugPrint('Email: ${session.user.email}');
      debugPrint('Expires At: ${session.expiresAt}');
      debugPrint('Is Expired: ${session.isExpired}');
      debugPrint('===============================');
    } else {
      debugPrint('=== NO ACTIVE SESSION ($context) ===');
    }
  }

  final _dobController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;
  String? _fetchedEmail;
  String? _fetchedName;
  bool _isFetchingProfile = false;

  @override
  void initState() {
    super.initState();

    // Set default date of birth to 01/01/2000
    _selectedDate = DateTime(2000, 1, 1);
    _dobController.text = "01/01/2000";

    if (widget.name != null) {
      _nameController.text = widget.name!;
    }

    // Extract username from email if available
    if (widget.email != null) {
      _usernameController.text = _extractUsernameFromEmail(widget.email!);
    }

    if (widget.email == null) {
      _fetchProfileData();
    }
  }

  String _extractUsernameFromEmail(String email) {
    // Get the part before @ symbol
    final username = email.split('@').first;
    return username;
  }

  Future<void> _fetchProfileData() async {
    debugPrint('[SETUP] Fetching profile data from session...');

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('[SETUP] No session found');
        return;
      }

      debugPrint('[SETUP] Session found, User ID: ${session.user.id}');
      debugPrint('[SETUP] User email: ${session.user.email}');
      debugPrint('[SETUP] User metadata: ${session.user.userMetadata}');

      // Extract data from session (works for all auth methods)
      final email = session.user.email;

      // For OAuth (Google, GitHub), metadata contains full_name/name
      // For email/password, metadata is empty and name field stays empty
      final fullName =
          session.user.userMetadata?['full_name'] ??
          session.user.userMetadata?['name'];

      debugPrint('[SETUP] Extracted email: $email');
      debugPrint('[SETUP] Extracted name: $fullName');

      if (!mounted) return;

      setState(() {
        _fetchedEmail = email;
        _fetchedName = fullName;
        if (_fetchedName != null && _fetchedName!.isNotEmpty) {
          _nameController.text = _fetchedName!;
          debugPrint('[SETUP] Pre-filled name: $_fetchedName');
        }
        // Extract username from email
        if (email != null) {
          _usernameController.text = _extractUsernameFromEmail(email);
          debugPrint(
            '[SETUP] Pre-filled username: ${_usernameController.text}',
          );
        }
        _isFetchingProfile = false;
      });
    } catch (e, stackTrace) {
      debugPrint('[SETUP] Error fetching profile from session: $e');
      debugPrint('[SETUP] Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _isFetchingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _completeSetup() async {
    debugPrint('[SETUP] Complete setup button pressed');
    debugPrint('   - Username: ${_usernameController.text}');
    debugPrint('   - Full Name: ${_nameController.text}');
    debugPrint('   - DOB selected: ${_selectedDate != null}');

    if (_usernameController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _selectedDate == null) {
      debugPrint('[SETUP] Validation failed: missing fields');
      setState(() {
        _errorMessage = "Please fill in all fields";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('[SETUP] No session found');
        throw Exception("Not authenticated");
      }

      debugPrint('[SETUP] Session found, User ID: ${session.user.id}');

      // Debug session before setup
      _debugPrintSession('BEFORE SETUP');

      final token = session.accessToken;
      final serverUrl = dotenv.env["SERVER_URL"]!;

      final dobString = _selectedDate!.toIso8601String().split('T')[0];

      debugPrint('[SETUP] Sending POST to: $serverUrl/api/user/setup');
      debugPrint(
        '📤 [SETUP] Request body: {username: ${_usernameController.text.trim()}, fullName: ${_nameController.text.trim()}, dob: $dobString}',
      );

      final response = await http.post(
        Uri.parse("$serverUrl/api/user/setup"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "fullName": _nameController.text.trim(),
          "dob": dobString,
        }),
      );

      debugPrint('[SETUP] Response status: ${response.statusCode}');
      debugPrint('[SETUP] Response body: ${response.body}');

      // Debug session after setup response
      _debugPrintSession('AFTER SETUP RESPONSE');

      if (!mounted) return;

      if (response.statusCode == 200) {
        debugPrint('[SETUP] Setup successful! Showing success modal');
        _showSuccessModal();
      } else {
        debugPrint('[SETUP] Setup failed: ${response.statusCode}');
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data["error"] ?? "Failed to complete setup";
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[SETUP] Error completing setup: $e');
      debugPrint('[SETUP] Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
        _isLoading = false;
      });
    }
  }

  void _showSuccessModal() {
    debugPrint('[SETUP] Showing success modal');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 60, color: Colors.white),
              ),
              SizedBox(height: 32),
              Text(
                "Welcome!",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Your account is ready",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    debugPrint('[SETUP] Waiting 2 seconds before redirecting to /home');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        debugPrint('[SETUP] Redirecting to /home');
        context.go("/home");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Complete Your Profile",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Tell us a bit more about yourself",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 40),
              if (_isFetchingProfile)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else ...[
                if (widget.email != null || _fetchedEmail != null) ...[
                  Text(
                    "Email",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.email ?? _fetchedEmail!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ],
              Text(
                "Username",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "username",
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Name",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: !_isLoading,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "Your Name",
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Date of Birth",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _dobController,
                enabled: !_isLoading,
                readOnly: true,
                onTap: _isLoading ? null : _selectDate,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "DD/MM/YYYY",
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          "Complete Setup",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
