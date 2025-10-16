import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:flutter_dotenv/flutter_dotenv.dart";
import "widgets/question_card.dart";
import "widgets/question_type_modal.dart";
import "widgets/save_questions_dialog.dart";

class AddQuestionsPage extends StatefulWidget {
  final String quizId;

  const AddQuestionsPage({required this.quizId, super.key});

  @override
  State<AddQuestionsPage> createState() => _AddQuestionsPageState();
}

class _AddQuestionsPageState extends State<AddQuestionsPage> {
  final List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;

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

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _questions.add(result);
      });
    }
  }

  Future<void> _saveQuestions() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one question"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception("Not authenticated");
      }

      final serverUrl = dotenv.env["SERVER_URL"] ?? "http://localhost:8000";
      final response = await http.post(
        Uri.parse("$serverUrl/api/question/bulk"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${session.accessToken}",
        },
        body: jsonEncode({
          "quizId": widget.quizId,
          "questions": _questions
              .asMap()
              .entries
              .map(
                (e) => {
                  "type": e.value["type"],
                  "questionText": e.value["questionText"],
                  "data": e.value["data"],
                  "orderIndex": e.key,
                },
              )
              .toList(),
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          context.go("/quiz/${widget.quizId}");
        }
      } else {
        throw Exception("Failed to save questions: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving questions: $e"),
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A2433),
      appBar: AppBar(
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
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          if (_questions.isEmpty)
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
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          _questions[index] = result;
                        });
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
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            _questions[index] = result;
                          });
                        }
                      },
                      onDelete: () {
                        setState(() {
                          _questions.removeAt(index);
                        });
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
              onTap: _questions.isEmpty
                  ? _showQuestionTypeModal
                  : () {
                      showSaveQuestionsDialog(
                        context: context,
                        onAddMore: _showQuestionTypeModal,
                        onSave: _saveQuestions,
                      );
                    },
              child: Container(
                width: 70,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF6949FF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF563DCB),
                      offset: Offset(0, 4),
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
