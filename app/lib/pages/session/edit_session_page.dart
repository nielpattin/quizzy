import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:intl/intl.dart";
import "package:image_picker/image_picker.dart";
import "../../services/upload_service.dart";
import "../quiz/widgets/cover_image_picker.dart";

class EditSessionPage extends StatefulWidget {
  final String sessionId;

  const EditSessionPage({super.key, required this.sessionId});

  @override
  State<EditSessionPage> createState() => _EditSessionPageState();
}

class _EditSessionPageState extends State<EditSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool _isPublic = false;
  bool _hasEndTime = false;
  DateTime? _endTime;

  XFile? _coverImage;
  String? _existingImageUrl;

  Map<String, dynamic>? _sessionData;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    try {
      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) {
        throw Exception("No active session");
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      final response = await http.get(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}"),
        headers: {"Authorization": "Bearer ${authSession.accessToken}"},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to load session data");
      }

      final sessionData = jsonDecode(response.body);

      setState(() {
        _sessionData = sessionData;
        _titleController.text = sessionData["title"] ?? "";
        _descriptionController.text = sessionData["description"] ?? "";
        _existingImageUrl = sessionData["imageUrl"];
        _isPublic = sessionData["isPublic"] ?? false;
        _hasEndTime = sessionData["hasEndTime"] ?? false;
        if (sessionData["endTime"] != null) {
          _endTime = DateTime.parse(sessionData["endTime"]);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_hasEndTime && _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an end time"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authSession = Supabase.instance.client.auth.currentSession;
      if (authSession == null) {
        throw Exception("No active session");
      }

      // Upload image if a new one was selected
      String? imageUrl = _existingImageUrl;
      if (_coverImage != null) {
        final imageData = await UploadService.uploadImage(_coverImage!);
        imageUrl = imageData["url"] as String?;
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      final response = await http.put(
        Uri.parse("$serverUrl/api/session/${widget.sessionId}"),
        headers: {
          "Authorization": "Bearer ${authSession.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "title": _titleController.text,
          "description": _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          "imageUrl": imageUrl,
          "isPublic": _isPublic,
          // maxParticipants is locked at session creation and cannot be edited
          "hasEndTime": _hasEndTime,
          "endTime": _hasEndTime && _endTime != null
              ? _endTime!.toIso8601String()
              : null,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update session");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime ?? now),
      );

      if (time != null) {
        setState(() {
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _coverImage = pickedFile;
          _existingImageUrl =
              null; // Clear existing URL when new image is picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking image: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Session",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveSession,
              child: Text(
                "Save",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoverImagePicker(
                      coverImage: _coverImage,
                      imageUrl: _existingImageUrl,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 20),
                    _buildTitleField(theme),
                    const SizedBox(height: 20),
                    _buildDescriptionField(theme),
                    const SizedBox(height: 20),
                    _buildPublicSwitch(theme),
                    const SizedBox(height: 20),
                    _buildEndTimeSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Title",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: "Enter session title",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Title is required";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Description",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: "Enter session description (optional)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPublicSwitch(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(
          "Public Session",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _isPublic
              ? "Anyone can join this session"
              : "Only people with the code can join",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        value: _isPublic,
        onChanged: (value) {
          setState(() {
            _isPublic = value;
          });
        },
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildEndTimeSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Set End Time",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Automatically end the session at a specific time",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              value: _hasEndTime,
              onChanged: (value) {
                setState(() {
                  _hasEndTime = value;
                  if (!value) {
                    _endTime = null;
                  }
                });
              },
              activeColor: theme.colorScheme.primary,
            ),
            if (_hasEndTime) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _selectEndTime,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _endTime == null
                      ? "Select End Time"
                      : DateFormat('MMM dd, yyyy • HH:mm').format(_endTime!),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "Error Loading Session",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "Unknown error occurred",
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
