import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:http/http.dart" as http;
import "dart:convert";
import "../../services/api_service.dart";

class CodeTab extends StatefulWidget {
  const CodeTab({super.key});

  @override
  State<CodeTab> createState() => _CodeTabState();
}

class _CodeTabState extends State<CodeTab> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // debugPrint("DEBUG: CodeTab initState - widget is initializing");
  }

  @override
  void dispose() {
    // debugPrint("DEBUG: CodeTab dispose - widget is being disposed");
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinSession() async {
    // debugPrint("DEBUG: CodeTab _joinSession called");
    final code = _codeController.text.trim().toUpperCase();
    // debugPrint("DEBUG: CodeTab entered code: $code");

    if (code.isEmpty || code.length < 4) {
      debugPrint(
        "DEBUG: CodeTab validation failed - code is empty or less than 4 characters",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid code (at least 4 characters)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // debugPrint("DEBUG: CodeTab validation passed - setting loading state");
    setState(() => _isLoading = true);

    try {
      debugPrint(
        "DEBUG: CodeTab calling ApiService.getSessionByCode with code: $code",
      );
      final session = await ApiService.getSessionByCode(code);
      debugPrint(
        "DEBUG: CodeTab API call successful - session data: ${session.toString()}",
      );

      if (mounted) {
        // debugPrint("DEBUG: CodeTab showing game found dialog");
        final parentContext = context; // Capture parent context before dialog
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Found Game!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Quiz: ${session["title"]}"),
                const SizedBox(height: 8),
                Text("Host: ${session["host"]["fullName"]}"),
                const SizedBox(height: 8),
                Text("Status: ${session["isLive"] ? "Live" : "Waiting"}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // debugPrint("DEBUG: CodeTab dialog cancel button pressed");
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // debugPrint("DEBUG: CodeTab dialog join button pressed");
                  Navigator.of(dialogContext).pop(); // Close dialog
                  final sessionId = session["id"];
                  debugPrint("DEBUG: CodeTab joining session: $sessionId");

                  // Call HTTP join endpoint to create participant record
                  try {
                    final authSession =
                        Supabase.instance.client.auth.currentSession;
                    if (authSession == null) {
                      throw Exception("No active session");
                    }

                    final serverUrl = dotenv.env["SERVER_URL"];
                    final response = await http.post(
                      Uri.parse("$serverUrl/api/session/$sessionId/join"),
                      headers: {
                        "Authorization": "Bearer ${authSession.accessToken}",
                        "Content-Type": "application/json",
                      },
                    );

                    if (response.statusCode != 200 &&
                        response.statusCode != 201) {
                      final error = jsonDecode(response.body);
                      throw Exception(
                        error["error"] ?? "Failed to join session",
                      );
                    }

                    debugPrint("DEBUG: CodeTab successfully joined session");

                    // Navigate to session detail page using parentContext
                    if (mounted) {
                      parentContext.push('/quiz/session/detail/$sessionId');
                    }
                  } catch (e) {
                    debugPrint("DEBUG: CodeTab failed to join session: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text("Failed to join: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Join"),
              ),
            ],
          ),
        );
      } else {
        // debugPrint("DEBUG: CodeTab not showing dialog - widget not mounted");
      }
    } catch (e) {
      // debugPrint("DEBUG: CodeTab API call failed with error: ${e.toString()}");
      if (mounted) {
        // debugPrint("DEBUG: CodeTab showing error snackbar");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      } else {
        debugPrint(
          "DEBUG: CodeTab not showing error snackbar - widget not mounted",
        );
      }
    } finally {
      if (mounted) {
        // debugPrint("DEBUG: CodeTab resetting loading state");
        setState(() => _isLoading = false);
      } else {
        debugPrint(
          "DEBUG: CodeTab not resetting loading state - widget not mounted",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint("DEBUG: CodeTab build called - loading state: $_isLoading");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.games_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 32),
          Text(
            "Enter Game Code",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Enter the code shared by the host to join the game session",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: "ABC123",
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
            keyboardType: TextInputType.text,
            maxLength: 10,
          ),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _joinSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Join Game",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
