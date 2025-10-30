import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "dart:convert";
import "../../services/upload_service.dart";
import "widgets/question_pickers.dart";
import "widgets/cover_image_picker.dart";
import "widgets/clean_answer_list.dart";
import "widgets/settings_toolbar.dart";

class CreateQuestionPage extends StatefulWidget {
  final String quizId;
  final String questionType;
  final Map<String, dynamic>? existingQuestion;

  const CreateQuestionPage({
    required this.quizId,
    required this.questionType,
    this.existingQuestion,
    super.key,
  });

  @override
  State<CreateQuestionPage> createState() => _CreateQuestionPageState();
}

class _CreateQuestionPageState extends State<CreateQuestionPage> {
  final _questionController = TextEditingController();
  final _questionFocusNode = FocusNode();
  String _timeLimit = "20 sec";
  String _points = "100 coki";
  int? _correctAnswerIndex;
  XFile? _coverImage;
  late String _currentQuestionType;
  final List<TextEditingController> _answerControllers = [];
  int _answerCount = 4;
  int _questionCharCount = 0;
  bool _isSaving = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _currentQuestionType = widget.questionType;

    if (widget.existingQuestion != null) {
      _questionController.text = widget.existingQuestion!["questionText"] ?? "";
      _timeLimit = widget.existingQuestion!["timeLimit"] ?? "20 sec";
      _points = widget.existingQuestion!["points"] ?? "100 coki";

      // Load existing image URL from database
      if (widget.existingQuestion!["imageUrl"] != null) {
        _existingImageUrl = widget.existingQuestion!["imageUrl"] as String;
      }

      if (widget.existingQuestion!["data"] != null) {
        final data = widget.existingQuestion!["data"] as Map<String, dynamic>;

        if (_currentQuestionType == "single_choice") {
          final options = data["options"] as List<dynamic>?;
          if (options != null) {
            _answerCount = options.length.clamp(2, 5);
            for (int i = 0; i < _answerCount; i++) {
              _answerControllers.add(
                TextEditingController()
                  ..text = i < options.length
                      ? options[i].toString()
                      : "Answer",
              );
            }
          } else {
            _initializeAnswers();
          }
          _correctAnswerIndex = data["correctIndex"] as int?;
        } else if (_currentQuestionType == "true_false") {
          final correctAnswer = data["correctAnswer"] as bool?;
          _correctAnswerIndex = correctAnswer == true ? 0 : 1;
        }
      } else {
        _initializeAnswers();
      }
    } else {
      _initializeAnswers();
    }

    _questionController.addListener(() {
      setState(() {
        _questionCharCount = _questionController.text.length;
      });
    });
  }

  void _initializeAnswers() {
    for (int i = 0; i < _answerCount; i++) {
      _answerControllers.add(TextEditingController()..text = "Answer");
    }
  }

  void _addAnswer() {
    if (_answerCount < 5) {
      setState(() {
        _answerCount++;
        _answerControllers.add(TextEditingController()..text = "Answer");
      });
    }
  }

  void _removeAnswer(int index) {
    if (_answerCount > 2) {
      setState(() {
        _answerControllers[index].dispose();
        _answerControllers.removeAt(index);
        _answerCount--;

        if (_correctAnswerIndex == index) {
          _correctAnswerIndex = null;
        } else if (_correctAnswerIndex != null &&
            _correctAnswerIndex! > index) {
          _correctAnswerIndex = _correctAnswerIndex! - 1;
        }
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _questionFocusNode.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _coverImage = pickedFile;
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image picker not available on this platform"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showTimeLimitPicker() {
    _questionFocusNode.unfocus();
    showTimeLimitPicker(context, _timeLimit, (time) {
      setState(() => _timeLimit = time);
    });
  }

  void _showPointsPicker() {
    _questionFocusNode.unfocus();
    showPointsPicker(context, _points, (points) {
      setState(() => _points = points);
    });
  }

  void _showQuestionTypePicker() {
    _questionFocusNode.unfocus();
    showQuestionTypePicker(context, _currentQuestionType, (type) {
      setState(() {
        final oldType = _currentQuestionType;
        _currentQuestionType = type;
        _correctAnswerIndex = null;

        // Initialize answer controllers when switching TO single_choice
        if (type == "single_choice" && _answerControllers.isEmpty) {
          _answerCount = 4;
          _initializeAnswers();
        }

        // Clear answer controllers when switching FROM single_choice
        if (oldType == "single_choice" && type != "single_choice") {
          for (var controller in _answerControllers) {
            controller.dispose();
          }
          _answerControllers.clear();
          _answerCount = 0;
        }
      });
    });
  }

  void _saveQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a question"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentQuestionType == "single_choice") {
      if (_correctAnswerIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select the correct answer"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      for (var controller in _answerControllers) {
        if (controller.text.trim().isEmpty ||
            controller.text.trim() == "Answer") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please fill all answer options"),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
    }

    if (_currentQuestionType == "true_false" && _correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select True or False"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final questionData = {
      "type": _currentQuestionType,
      "questionText": _questionController.text.trim(),
      "timeLimit": _timeLimit,
      "points": _points,
      if (_coverImage != null) "coverImagePath": _coverImage!.path,
      "data": {
        if (_currentQuestionType == "single_choice") ...{
          "options": _answerControllers.map((c) => c.text.trim()).toList(),
          "correctIndex": _correctAnswerIndex,
        },
        if (_currentQuestionType == "true_false") ...{
          "correctAnswer": _correctAnswerIndex == 0,
        },
      },
    };

    if (widget.existingQuestion != null &&
        widget.existingQuestion!.containsKey("id")) {
      await _updateExistingQuestion(questionData);
    } else {
      await _createNewQuestion(questionData);
    }
  }

  Future<void> _createNewQuestion(Map<String, dynamic> questionData) async {
    setState(() => _isSaving = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception("Not authenticated");
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      String? imageUrl;

      // Upload image if exists
      if (_coverImage != null) {
        final imageData = await UploadService.uploadImage(_coverImage!);
        imageUrl = imageData["url"] as String?;
      }

      final response = await http.post(
        Uri.parse("$serverUrl/api/question"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${session.accessToken}",
        },
        body: jsonEncode({
          "quizId": widget.quizId,
          "type": questionData["type"],
          "questionText": questionData["questionText"],
          "imageUrl": imageUrl,
          "data": questionData["data"],
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Question created successfully"),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        }
      } else {
        throw Exception("Failed to create question: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating question: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateExistingQuestion(
    Map<String, dynamic> questionData,
  ) async {
    setState(() => _isSaving = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception("Not authenticated");
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      final questionId = widget.existingQuestion!["id"];
      String? imageUrl = widget.existingQuestion!["imageUrl"] as String?;

      // Only upload if user picked a NEW image
      if (_coverImage != null) {
        final imageData = await UploadService.uploadImage(_coverImage!);
        imageUrl = imageData["url"] as String?;
      }

      final response = await http.put(
        Uri.parse("$serverUrl/api/question/$questionId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${session.accessToken}",
        },
        body: jsonEncode({
          "type": questionData["type"],
          "questionText": questionData["questionText"],
          "imageUrl": imageUrl,
          "data": questionData["data"],
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Question updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        }
      } else {
        throw Exception("Failed to update question: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating question: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.existingQuestion != null ? "Edit Question" : "Create Question",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          _questionFocusNode.unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoverImagePicker(
                      coverImage: _coverImage,
                      imageUrl: _existingImageUrl,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "What's your question?",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _questionController,
                            focusNode: _questionFocusNode,
                            enableInteractiveSelection: true,
                            maxLength: 1000,
                            minLines: 2,
                            maxLines: 8,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: "Type your question here...",
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              counterText: "",
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$_questionCharCount/1000",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 28),
                    if (_currentQuestionType == "single_choice" ||
                        _currentQuestionType == "true_false")
                      CleanAnswerList(
                        questionType: _currentQuestionType,
                        correctAnswerIndex: _correctAnswerIndex,
                        answerControllers: _answerControllers,
                        answerCount: _answerCount,
                        onMarkCorrect: (index) {
                          setState(() => _correctAnswerIndex = index);
                        },
                        onAddAnswer: _currentQuestionType == "single_choice"
                            ? _addAnswer
                            : null,
                        onRemoveAnswer: _currentQuestionType == "single_choice"
                            ? _removeAnswer
                            : null,
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SettingsToolbar(
              timeLimit: _timeLimit,
              points: _points,
              questionType: _currentQuestionType,
              onTimeTap: _showTimeLimitPicker,
              onPointsTap: _showPointsPicker,
              onTypeTap: _showQuestionTypePicker,
            ),
          ],
        ),
      ),
    );
  }
}
