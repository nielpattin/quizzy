import 'package:flutter/foundation.dart';

class QuizSessionController extends ChangeNotifier {
  final List<dynamic> questions;
  final String sessionId;

  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showResult = false;
  int _score = 0;
  final List<int?> _userAnswers = [];

  QuizSessionController({required this.questions, required this.sessionId}) {
    _userAnswers.addAll(List.filled(questions.length, null));
  }

  int get currentQuestionIndex => _currentQuestionIndex;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get showResult => _showResult;
  int get score => _score;
  List<int?> get userAnswers => _userAnswers;

  Map<String, dynamic> get currentQuestion => questions[_currentQuestionIndex];

  bool get isLastQuestion => _currentQuestionIndex == questions.length - 1;
  bool get isFirstQuestion => _currentQuestionIndex == 0;

  void selectAnswer(int index) {
    if (!_showResult) {
      _selectedAnswerIndex = index;
      notifyListeners();
    }
  }

  void submitAnswer() {
    if (_selectedAnswerIndex == null) return;

    final correctIndex = currentQuestion["data"]["correctIndex"] as int?;
    final correctAnswerRaw = currentQuestion["data"]["correctAnswer"];
    bool? correctAnswer;
    if (correctAnswerRaw is bool) {
      correctAnswer = correctAnswerRaw;
    } else if (correctAnswerRaw is String) {
      correctAnswer = correctAnswerRaw.toLowerCase() == 'true';
    }

    bool isCorrect = false;
    if (correctIndex != null) {
      isCorrect = _selectedAnswerIndex == correctIndex;
    } else if (correctAnswer != null) {
      isCorrect =
          (_selectedAnswerIndex == 0 && correctAnswer) ||
          (_selectedAnswerIndex == 1 && !correctAnswer);
    }

    _userAnswers[_currentQuestionIndex] = _selectedAnswerIndex;
    _showResult = true;
    if (isCorrect) _score++;

    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      _currentQuestionIndex++;
      _selectedAnswerIndex = _userAnswers[_currentQuestionIndex];
      _showResult = false;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      _selectedAnswerIndex = _userAnswers[_currentQuestionIndex];
      _showResult = _userAnswers[_currentQuestionIndex] != null;
      notifyListeners();
    }
  }

  void reset() {
    _currentQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _showResult = false;
    _score = 0;
    _userAnswers.clear();
    _userAnswers.addAll(List.filled(questions.length, null));
    notifyListeners();
  }
}
