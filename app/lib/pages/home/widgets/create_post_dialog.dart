import "package:flutter/material.dart";
import "../../../services/api_service.dart";
import "../../../models/post.dart";

class CreatePostDialog extends StatefulWidget {
  final VoidCallback onPostCreated;

  const CreatePostDialog({super.key, required this.onPostCreated});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitPost(
    String postType, {
    Map<String, dynamic>? quizData,
  }) async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post text cannot be empty")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.createPost(
        _textController.text,
        postType: postType,
        questionType: quizData?['questionType'],
        questionText: quizData?['questionText'],
        questionData: quizData?['questionData'],
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPostCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post created successfully")),
        );
      }
    } catch (e) {
      debugPrint("[CreatePostDialog] Error creating post: $e");
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to create post: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Text(
                    "Create Post",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.text_fields), text: "Text"),
                Tab(icon: Icon(Icons.image), text: "Image"),
                Tab(icon: Icon(Icons.quiz), text: "Quiz"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TextTab(
                    textController: _textController,
                    isSubmitting: _isSubmitting,
                    onSubmit: () => _submitPost('text'),
                  ),
                  _ImageTab(
                    textController: _textController,
                    isSubmitting: _isSubmitting,
                    onSubmit: () => _submitPost('image'),
                  ),
                  _QuizTab(
                    textController: _textController,
                    isSubmitting: _isSubmitting,
                    onSubmit: _submitPost,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  final TextEditingController textController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _TextTab({
    required this.textController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 8,
            minLines: 5,
            autofocus: true,
            textInputAction: TextInputAction.newline,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageTab extends StatelessWidget {
  final TextEditingController textController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _ImageTab({
    required this.textController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: "Write a caption...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Image upload coming soon",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizTab extends StatefulWidget {
  final TextEditingController textController;
  final bool isSubmitting;
  final Function(String postType, {Map<String, dynamic>? quizData}) onSubmit;

  const _QuizTab({
    required this.textController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  QuestionType _selectedType = QuestionType.multipleChoice;
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int? _correctAnswerIndex;
  final Set<int> _correctAnswersSet = {};

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

  void _handleSubmit() {
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

    widget.onSubmit(
      'quiz',
      quizData: {
        'questionType': _selectedType.toJson(),
        'questionText': _questionController.text.trim(),
        'questionData': {'options': options, 'correctAnswer': correctAnswer},
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.textController,
              decoration: InputDecoration(
                hintText: "Post caption",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 2,
              minLines: 1,
            ),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isSubmitting ? null : _handleSubmit,
                child: widget.isSubmitting
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
