import "dart:io";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "../../../models/post.dart";
import "../../../services/upload_service.dart";

class CreateQuizPostPage extends StatefulWidget {
  const CreateQuizPostPage({super.key});

  @override
  State<CreateQuizPostPage> createState() => _CreateQuizPostPageState();
}

class _CreateQuizPostPageState extends State<CreateQuizPostPage> {
  QuestionType _selectedType = QuestionType.multipleChoice;
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int? _correctAnswerIndex;
  final Set<int> _correctAnswersSet = {};
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        if (_correctAnswerIndex == index) {
          _correctAnswerIndex = null;
        } else if (_correctAnswerIndex != null &&
            _correctAnswerIndex! > index) {
          _correctAnswerIndex = _correctAnswerIndex! - 1;
        }
        _correctAnswersSet.removeWhere((i) => i >= _optionControllers.length);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Question text is required")),
      );
      return;
    }

    final options = _selectedType == QuestionType.trueFalse
        ? ['True', 'False']
        : _optionControllers.map((c) => c.text.trim()).toList();

    if (_selectedType != QuestionType.trueFalse &&
        options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All options must be filled")),
      );
      return;
    }

    dynamic correctAnswer;
    if (_selectedType == QuestionType.checkbox) {
      if (_correctAnswersSet.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select at least one correct answer")),
        );
        return;
      }
      correctAnswer = _correctAnswersSet.toList()..sort();
    } else {
      if (_correctAnswerIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select the correct answer")),
        );
        return;
      }
      correctAnswer = _correctAnswerIndex;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final imageData = await UploadService.uploadImage(_selectedImage!);
        imageUrl = imageData['url'] as String;
      }

      final postData = {
        'text': _questionController.text.trim(),
        'postType': 'quiz',
        'imageUrl': imageUrl,
        'questionType': _selectedType.toJson(),
        'questionText': _questionController.text.trim(),
        'questionData': {'options': options, 'correctAnswer': correctAnswer},
      };

      if (mounted) {
        context.pop(postData);
      }
    } catch (e) {
      debugPrint("[CreateQuizPostPage] Error uploading media: $e");
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to upload media: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Quiz Post"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quiz Image (Optional)",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Tap to add image",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedImage = null),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text("Remove image"),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<QuestionType>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: "Question Type",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: QuestionType.multipleChoice,
                          child: Text("Multiple Choice"),
                        ),
                        DropdownMenuItem(
                          value: QuestionType.trueFalse,
                          child: Text("True/False"),
                        ),
                        DropdownMenuItem(
                          value: QuestionType.checkbox,
                          child: Text("Checkbox (Multiple Answers)"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          _correctAnswerIndex = null;
                          _correctAnswersSet.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        labelText: "Question",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedType == QuestionType.trueFalse
                          ? "Select Correct Answer"
                          : "Options",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedType == QuestionType.trueFalse)
                      Column(
                        children: [
                          RadioListTile<int>(
                            title: const Text("True"),
                            value: 0,
                            groupValue: _correctAnswerIndex,
                            onChanged: (value) {
                              setState(() {
                                _correctAnswerIndex = value;
                              });
                            },
                          ),
                          RadioListTile<int>(
                            title: const Text("False"),
                            value: 1,
                            groupValue: _correctAnswerIndex,
                            onChanged: (value) {
                              setState(() {
                                _correctAnswerIndex = value;
                              });
                            },
                          ),
                        ],
                      )
                    else
                      ..._optionControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              if (_selectedType == QuestionType.checkbox)
                                Checkbox(
                                  value: _correctAnswersSet.contains(index),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _correctAnswersSet.add(index);
                                      } else {
                                        _correctAnswersSet.remove(index);
                                      }
                                    });
                                  },
                                )
                              else
                                Radio<int>(
                                  value: index,
                                  groupValue: _correctAnswerIndex,
                                  onChanged: (value) {
                                    setState(() {
                                      _correctAnswerIndex = value;
                                    });
                                  },
                                ),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: "Option ${index + 1}",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                              if (_optionControllers.length > 2)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeOption(index),
                                ),
                            ],
                          ),
                        );
                      }),
                    if (_selectedType != QuestionType.trueFalse &&
                        _optionControllers.length < 6)
                      TextButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Option"),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Post Quiz"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
