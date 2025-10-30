import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "widgets/question_card.dart";
import "widgets/question_type_modal.dart";
import "../../services/quiz_service.dart";

class AddQuestionsPage extends StatefulWidget {
  final String quizId;

  const AddQuestionsPage({required this.quizId, super.key});

  @override
  State<AddQuestionsPage> createState() => _AddQuestionsPageState();
}

class _AddQuestionsPageState extends State<AddQuestionsPage> {
  final List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  bool _isLoadingQuestions = true;

  @override
  void initState() {
    super.initState();
    _loadExistingQuestions();
  }

  Future<void> _loadExistingQuestions() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() => _isLoadingQuestions = false);
        return;
      }

      final serverUrl = dotenv.env["SERVER_URL"];
      final response = await http.get(
        Uri.parse("$serverUrl/api/quiz/${widget.quizId}/questions"),
        headers: {"Authorization": "Bearer ${session.accessToken}"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> questions = jsonDecode(response.body);
        setState(() {
          _questions.clear();
          _questions.addAll(
            questions
                .map(
                  (q) => {
                    "id": q["id"],
                    "type": q["type"],
                    "questionText": q["questionText"],
                    "imageUrl": q["imageUrl"],
                    "data": q["data"],
                    "orderIndex": q["orderIndex"],
                  },
                )
                .toList(),
          );
          _isLoadingQuestions = false;
        });
      } else {
        setState(() => _isLoadingQuestions = false);
      }
    } catch (e) {
      setState(() => _isLoadingQuestions = false);
    }
  }

  void _showQuestionTypeModal() {
    showQuestionTypeModal(
      context: context,
      onTypeSelected: _navigateToCreateQuestion,
    );
  }

  void _navigateToCreateQuestion(String type) async {
    final result = await context.push(
      "/quiz/${widget.quizId}/create-question?type=$type",
    );

    if (result == true) {
      _loadExistingQuestions();
    }
  }

  Future<void> _deleteQuestion(int index) async {
    final question = _questions[index];

    if (question.containsKey("id")) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          throw Exception("Not authenticated");
        }

        final serverUrl = dotenv.env["SERVER_URL"];
        final response = await http.delete(
          Uri.parse("$serverUrl/api/question/${question["id"]}"),
          headers: {"Authorization": "Bearer ${session.accessToken}"},
        );

        if (response.statusCode != 200) {
          throw Exception("Failed to delete question");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Question deleted"),
              backgroundColor: Colors.green,
            ),
          );
          _loadExistingQuestions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting question: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text("Preview Quiz"),
              onTap: () {
                context.pop();
                _previewQuiz();
              },
            ),
            ListTile(
              leading: const Icon(Icons.reorder),
              title: const Text("Reorder Questions"),
              enabled: _questions.isNotEmpty,
              onTap: () {
                context.pop();
                _showReorderModal();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text(
                "Delete All Questions",
                style: TextStyle(color: Colors.red),
              ),
              enabled: _questions.isNotEmpty,
              onTap: () {
                context.pop();
                _showDeleteAllDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _previewQuiz() {
    context.push("/quiz/${widget.quizId}/play?preview=true");
  }

  void _showReorderModal() {
    showDialog(
      context: context,
      builder: (context) => _ReorderQuestionsDialog(
        questions: List.from(_questions),
        onReorder: _handleReorder,
      ),
    );
  }

  Future<void> _handleReorder(
    List<Map<String, dynamic>> reorderedQuestions,
  ) async {
    try {
      final questionsOrder = reorderedQuestions
          .asMap()
          .entries
          .map((entry) => {"id": entry.value["id"], "orderIndex": entry.key})
          .toList();

      await QuizService.reorderQuestions(widget.quizId, questionsOrder);

      setState(() {
        _questions.clear();
        _questions.addAll(reorderedQuestions);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Questions reordered successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error reordering questions: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAllDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Delete All Questions?",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              "This will delete all ${_questions.length} questions. This action cannot be undone.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.pop();
                _deleteAllQuestions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Delete All Questions"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAllQuestions() async {
    try {
      await QuizService.deleteAllQuestions(widget.quizId);

      setState(() {
        _questions.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All questions deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting questions: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2433),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/quiz/${widget.quizId}");
            }
          },
        ),
        title: const Text(
          "Questions",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMenuOptions,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoadingQuestions)
            const Center(child: CircularProgressIndicator())
          else if (_questions.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 80, color: Color(0xFF616161)),
                  SizedBox(height: 16),
                  Text(
                    "No questions yet",
                    style: TextStyle(fontSize: 20, color: Color(0xFF616161)),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () async {
                      final result = await context.push(
                        "/quiz/${widget.quizId}/create-question?type=${question["type"]}",
                        extra: question,
                      );
                      if (result == true) {
                        _loadExistingQuestions();
                      }
                    },
                    child: QuestionCard(
                      question: question,
                      index: index,
                      onEdit: () async {
                        final result = await context.push(
                          "/quiz/${widget.quizId}/create-question?type=${question["type"]}",
                          extra: question,
                        );
                        if (result == true) {
                          _loadExistingQuestions();
                        }
                      },
                      onDelete: () {
                        _deleteQuestion(index);
                      },
                    ),
                  ),
                );
              },
            ),
          Positioned(
            right: 20,
            bottom: 20,
            child: GestureDetector(
              onTap: _showQuestionTypeModal,
              child: Container(
                width: 70,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "+",
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReorderQuestionsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final Function(List<Map<String, dynamic>>) onReorder;

  const _ReorderQuestionsDialog({
    required this.questions,
    required this.onReorder,
  });

  @override
  State<_ReorderQuestionsDialog> createState() =>
      _ReorderQuestionsDialogState();
}

class _ReorderQuestionsDialogState extends State<_ReorderQuestionsDialog> {
  late List<Map<String, dynamic>> _questions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final temp = _questions[index];
        _questions[index] = _questions[index - 1];
        _questions[index - 1] = temp;
      });
    }
  }

  void _moveDown(int index) {
    if (index < _questions.length - 1) {
      setState(() {
        final temp = _questions[index];
        _questions[index] = _questions[index + 1];
        _questions[index + 1] = temp;
      });
    }
  }

  void _moveToTop(int index) {
    if (index > 0) {
      setState(() {
        final item = _questions.removeAt(index);
        _questions.insert(0, item);
      });
    }
  }

  void _moveToBottom(int index) {
    if (index < _questions.length - 1) {
      setState(() {
        final item = _questions.removeAt(index);
        _questions.add(item);
      });
    }
  }

  Future<void> _saveOrder() async {
    setState(() => _isSaving = true);
    await widget.onReorder(_questions);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Reorder Questions",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question["questionText"] ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 20),
                                onPressed: index > 0
                                    ? () => _moveUp(index)
                                    : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_downward,
                                  size: 20,
                                ),
                                onPressed: index < _questions.length - 1
                                    ? () => _moveDown(index)
                                    : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                enabled: index > 0,
                                onTap: () => _moveToTop(index),
                                child: const Text("Move to Top"),
                              ),
                              PopupMenuItem(
                                enabled: index < _questions.length - 1,
                                onTap: () => _moveToBottom(index),
                                child: const Text("Move to Bottom"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Save Order"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
