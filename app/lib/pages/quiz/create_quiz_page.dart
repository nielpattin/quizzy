import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:image_picker/image_picker.dart";
import "../../services/api_service.dart";

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = "General Knowledge";
  String? _selectedCollectionId;
  bool _isPublic = true;
  bool _questionsVisible = false;
  bool _isLoading = false;
  bool _loadingCollections = false;
  File? _selectedImageFile;
  List<Map<String, dynamic>> _collections = [];

  final List<String> _categories = [
    "General Knowledge",
    "Science",
    "Math",
    "History",
    "Geography",
    "Literature",
    "Music",
    "Movies",
    "Sports",
    "Technology",
    "Programming",
    "Art",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() => _loadingCollections = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final data = await ApiService.getUserCollections(userId);
        setState(() => _collections = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint("Error loading collections: $e");
    } finally {
      setState(() => _loadingCollections = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImageFile = File(image.path);
    });
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception("Not authenticated");
      }

      String? imageUrl;
      if (_selectedImageFile != null) {
        final imageData = await UploadService.uploadImage(_selectedImageFile!);
        imageUrl = imageData["url"] as String?;
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      final response = await http.post(
        Uri.parse("$serverUrl/api/quiz"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${session.accessToken}",
        },
        body: jsonEncode({
          "title": _titleController.text.trim(),
          "description": _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          "category": _selectedCategory,
          if (_selectedCollectionId != null)
            "collectionId": _selectedCollectionId,
          if (imageUrl != null) "imageUrl": imageUrl,
          "isPublic": _isPublic,
          "questionsVisible": _questionsVisible,
        }),
      );

      if (response.statusCode == 201) {
        final quizData = jsonDecode(response.body);
        final quizId = quizData["id"];

        if (mounted) {
          context.go("/quiz/$quizId/add-questions");
        }
      } else {
        throw Exception("Failed to create quiz: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating quiz: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Create Quiz"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Quiz Details",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedImageFile != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImageFile!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () =>
                            setState(() => _selectedImageFile = null),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text("Add Cover Image (Optional)"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Quiz Title",
                  hintText: "Enter a catchy title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Title is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Description (optional)",
                  hintText: "What is this quiz about?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedCollectionId,
                decoration: InputDecoration(
                  labelText: "Collection (Optional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _loadingCollections
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("None"),
                  ),
                  ..._collections.map((collection) {
                    return DropdownMenuItem<String?>(
                      value: collection["id"] as String,
                      child: Text(collection["title"] as String),
                    );
                  }).toList(),
                ],
                onChanged: _loadingCollections
                    ? null
                    : (value) {
                        setState(() => _selectedCollectionId = value);
                      },
              ),
              const SizedBox(height: 24),
              Text(
                "Settings",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text("Public Quiz"),
                subtitle: const Text("Anyone can find and play this quiz"),
                value: _isPublic,
                activeTrackColor: const Color(
                  0xFF64A7FF,
                ).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF64A7FF),
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text("Show Questions Before Playing"),
                subtitle: const Text(
                  "Players can see questions before starting",
                ),
                value: _questionsVisible,
                activeTrackColor: const Color(
                  0xFF64A7FF,
                ).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF64A7FF),
                onChanged: (value) {
                  setState(() => _questionsVisible = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _createQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64A7FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Continue to Add Questions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
