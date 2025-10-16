import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "dart:io";
import "widgets/property_chips.dart";
import "widgets/question_pickers.dart";
import "widgets/cover_image_picker.dart";
import "widgets/answer_options_section.dart";

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
  File? _coverImage;
  late String _currentQuestionType;
  final List<TextEditingController> _answerControllers = List.generate(
    4,
    (_) => TextEditingController()..text = "Answer",
  );
  int _questionCharCount = 0;

  @override
  void initState() {
    super.initState();
    _currentQuestionType = widget.questionType;

    if (widget.existingQuestion != null) {
      _questionController.text = widget.existingQuestion!["questionText"] ?? "";
      _timeLimit = widget.existingQuestion!["timeLimit"] ?? "20 sec";
      _points = widget.existingQuestion!["points"] ?? "100 coki";

      if (widget.existingQuestion!["data"] != null) {
        final data = widget.existingQuestion!["data"] as Map<String, dynamic>;

        if (_currentQuestionType == "multiple_choice") {
          final options = data["options"] as List<dynamic>?;
          if (options != null) {
            for (int i = 0; i < options.length && i < 4; i++) {
              _answerControllers[i].text = options[i].toString();
            }
          }
          _correctAnswerIndex = data["correctIndex"] as int?;
        } else if (_currentQuestionType == "true_false") {
          final correctAnswer = data["correctAnswer"] as bool?;
          _correctAnswerIndex = correctAnswer == true ? 0 : 1;
        }
      }
    }

    _questionController.addListener(() {
      setState(() {
        _questionCharCount = _questionController.text.length;
      });
    });
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
          _coverImage = File(pickedFile.path);
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
        _currentQuestionType = type;
        _correctAnswerIndex = null;
      });
    });
  }

  void _saveQuestion() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a question"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentQuestionType == "multiple_choice") {
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
      "data": {
        if (_currentQuestionType == "multiple_choice") ...{
          "options": _answerControllers.map((c) => c.text.trim()).toList(),
          "correctIndex": _correctAnswerIndex,
        },
        if (_currentQuestionType == "true_false") ...{
          "correctAnswer": _correctAnswerIndex == 0,
        },
      },
    };

    context.pop(questionData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.existingQuestion != null ? "Edit Question" : "Create Question",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _saveQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6949FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Save",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
            const SizedBox(height: 100),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          CoverImagePicker(
                            coverImage: _coverImage,
                            onTap: _pickImage,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: PropertyChip(
                                  icon: Icons.timer_rounded,
                                  label: _timeLimit,
                                  onTap: _showTimeLimitPicker,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PropertyChip(
                                  icon: Icons.stars_rounded,
                                  label: _points,
                                  onTap: _showPointsPicker,
                                ),
                              ),
                              const SizedBox(width: 12),
                              TypeChip(
                                label: _getTypeLabel(_currentQuestionType),
                                onTap: _showQuestionTypePicker,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2433),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextField(
                                  controller: _questionController,
                                  focusNode: _questionFocusNode,
                                  enableInteractiveSelection: true,
                                  maxLength: 1000,
                                  minLines: 1,
                                  maxLines: 6,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: "What's your question?",
                                    hintStyle: TextStyle(
                                      color: Color(0xFF525B6A),
                                      fontSize: 17,
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
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_currentQuestionType == "multiple_choice" ||
                              _currentQuestionType == "true_false") ...[
                            AnswerOptionsSection(
                              questionType: _currentQuestionType,
                              correctAnswerIndex: _correctAnswerIndex,
                              answerControllers: _answerControllers,
                              onMarkCorrect: (index) {
                                setState(() => _correctAnswerIndex = index);
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case "multiple_choice":
        return "Quiz";
      case "true_false":
        return "True/False";
      case "reorder":
        return "Reorder";
      case "type_answer":
        return "Type Answer";
      case "checkbox":
        return "Checkbox";
      case "drop_pin":
        return "Drop Pin";
      default:
        return "Quiz";
    }
  }
}
