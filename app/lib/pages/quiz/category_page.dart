import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../home/widgets/trending_card.dart";
import "../../services/api_service.dart";

class CategoryPage extends StatefulWidget {
  final String category;
  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool _isLoading = true;
  List<dynamic> _quizzes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategoryQuizzes();
  }

  Future<void> _loadCategoryQuizzes() async {
    try {
      final quizzes = await ApiService.getCategoryQuizzes(widget.category);
      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _loadCategoryQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(height: 24),
                      Text(
                        "Error Loading Quizzes",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: Text("Try Again"),
                      ),
                    ],
                  ),
                ),
              )
            : _quizzes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 24),
                      Text(
                        "No Quizzes Found",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "There are no quizzes in the ${widget.category} category yet.",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go("/create-quiz"),
                        child: Text("Create First Quiz"),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_quizzes.length} ${_quizzes.length == 1 ? 'Quiz' : 'Quizzes'}",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _quizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = _quizzes[index];
                          final user = quiz["user"] as Map<String, dynamic>?;
                          return InkWell(
                            onTap: () => context.push("/quiz/${quiz["id"]}"),
                            borderRadius: BorderRadius.circular(12),
                            child: TrendingCard(
                              title: quiz["title"] ?? "Untitled",
                              author: user?["fullName"] ?? "Unknown",
                              category: quiz["category"]?["name"] ?? "General",
                              count: quiz["playCount"] ?? 0,
                              isSessions: false,
                              quizId: quiz["id"]?.toString() ?? "1",
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
