class QuizDetail {
  final String id;
  final String title;
  final String collection;
  final String description;
  final String imageGradientStart;
  final String imageGradientEnd;
  final int questionCount;
  final int playCount;
  final int favoriteCount;
  final int shareCount;
  final String creatorName;
  final String creatorUsername;
  final String creatorId;
  final bool isOwner;
  final bool questionsVisible;
  final List<Question>? questions;

  QuizDetail({
    required this.id,
    required this.title,
    required this.collection,
    required this.description,
    required this.imageGradientStart,
    required this.imageGradientEnd,
    required this.questionCount,
    required this.playCount,
    required this.favoriteCount,
    required this.shareCount,
    required this.creatorName,
    required this.creatorUsername,
    required this.creatorId,
    required this.isOwner,
    this.questionsVisible = false,
    this.questions,
  });
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class MockQuizData {
  static QuizDetail getOwnerQuiz() {
    return QuizDetail(
      id: "1",
      title: "Modern Art or Just Scribbles?",
      collection: "Art Collection",
      description:
          "Test your knowledge of modern art movements and distinguish between famous artworks and random scribbles. Can you spot the difference?",
      imageGradientStart: "0xFF9C27B0",
      imageGradientEnd: "0xFF673AB7",
      questionCount: 16,
      playCount: 1234,
      favoriteCount: 89,
      shareCount: 45,
      creatorName: "Ly Nguyên",
      creatorUsername: "@lynguyen",
      creatorId: "current_user",
      isOwner: true,
      questionsVisible: true,
      questions: [
        Question(
          id: "q1",
          text: "Which of these is a famous Picasso painting?",
          options: [
            "Random Scribble A",
            "Guernica",
            "My Kid's Drawing",
            "Abstract Doodle",
          ],
          correctAnswerIndex: 1,
        ),
        Question(
          id: "q2",
          text: "Identify the Jackson Pollock artwork:",
          options: [
            "Spilled Paint #1",
            "Number 5, 1948",
            "Coffee Stain Art",
            "Random Splatter",
          ],
          correctAnswerIndex: 1,
        ),
        Question(
          id: "q3",
          text: "Which is NOT a real art movement?",
          options: ["Cubism", "Dadaism", "Scribbleism", "Surrealism"],
          correctAnswerIndex: 2,
        ),
        Question(
          id: "q4",
          text: "Who painted 'The Starry Night'?",
          options: [
            "Vincent van Gogh",
            "Claude Monet",
            "Pablo Picasso",
            "Salvador Dali",
          ],
          correctAnswerIndex: 0,
        ),
      ],
    );
  }

  static QuizDetail getOtherQuizHidden() {
    return QuizDetail(
      id: "2",
      title: "Guess the Song from 3 Words",
      collection: "Music Trivia",
      description:
          "Can you identify popular songs using only three words? Test your music knowledge across different genres and decades!",
      imageGradientStart: "0xFFE91E63",
      imageGradientEnd: "0xFFF44336",
      questionCount: 20,
      playCount: 5678,
      favoriteCount: 234,
      shareCount: 156,
      creatorName: "Music Maestro",
      creatorUsername: "@musicmaestro",
      creatorId: "other_user_1",
      isOwner: false,
      questionsVisible: false,
      questions: null,
    );
  }

  static QuizDetail getOtherQuizVisible() {
    return QuizDetail(
      id: "3",
      title: "Famous Entrepreneurs and Their Companies",
      collection: "Business & Startups",
      description:
          "Match iconic entrepreneurs with the companies they founded or led. From tech giants to innovative startups!",
      imageGradientStart: "0xFF00BCD4",
      imageGradientEnd: "0xFF009688",
      questionCount: 12,
      playCount: 3456,
      favoriteCount: 178,
      shareCount: 92,
      creatorName: "Business Guru",
      creatorUsername: "@bizguru",
      creatorId: "other_user_2",
      isOwner: false,
      questionsVisible: true,
      questions: [
        Question(
          id: "q1",
          text: "Who founded Tesla and SpaceX?",
          options: ["Jeff Bezos", "Elon Musk", "Bill Gates", "Mark Zuckerberg"],
          correctAnswerIndex: 1,
        ),
        Question(
          id: "q2",
          text: "Which company did Steve Jobs co-found?",
          options: ["Microsoft", "Google", "Apple", "Amazon"],
          correctAnswerIndex: 2,
        ),
        Question(
          id: "q3",
          text: "Who is the founder of Amazon?",
          options: ["Larry Page", "Jeff Bezos", "Warren Buffett", "Jack Ma"],
          correctAnswerIndex: 1,
        ),
        Question(
          id: "q4",
          text: "Who created Facebook (now Meta)?",
          options: [
            "Mark Zuckerberg",
            "Evan Spiegel",
            "Jack Dorsey",
            "Reed Hastings",
          ],
          correctAnswerIndex: 0,
        ),
      ],
    );
  }
}
