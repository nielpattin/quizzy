import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:http/http.dart" as http;
import "dart:convert";

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      final serverUrl = dotenv.env["SERVER_URL"]!;
      final response = await http.get(
        Uri.parse('$serverUrl/api/user/profile'),
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _fullNameController.text = data["fullName"] ?? "";
          _usernameController.text = data["username"] ?? "";
          _bioController.text = data["bio"] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Full name is required")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      final serverUrl = dotenv.env["SERVER_URL"]!;
      final response = await http.put(
        Uri.parse('$serverUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "fullName": _fullNameController.text.trim(),
          "username": _usernameController.text.trim(),
          "bio": _bioController.text.trim(),
        }),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profile updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Pass true to indicate profile was updated
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update profile"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      "Save",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SizedBox(height: 16),
                Text(
                  "Full Name",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    hintText: "Enter your full name",
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "Username",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: "Enter your username",
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "Bio",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Tell us about yourself...",
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
