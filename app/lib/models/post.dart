enum PostType {
  text,
  image,
  quiz;

  static PostType fromString(String value) {
    switch (value) {
      case 'text':
        return PostType.text;
      case 'image':
        return PostType.image;
      case 'quiz':
        return PostType.quiz;
      default:
        return PostType.text;
    }
  }

  String toJson() {
    switch (this) {
      case PostType.text:
        return 'text';
      case PostType.image:
        return 'image';
      case PostType.quiz:
        return 'quiz';
    }
  }
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  checkbox;

  static QuestionType fromString(String value) {
    switch (value) {
      case 'single_choice':
        return QuestionType.multipleChoice;
      case 'checkbox':
        return QuestionType.checkbox;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'single_answer':
        return QuestionType.checkbox;
      default:
        return QuestionType.multipleChoice;
    }
  }

  String toJson() {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'single_choice';
      case QuestionType.checkbox:
        return 'checkbox';
      case QuestionType.trueFalse:
        return 'true_false';
    }
  }
}

class QuestionData {
  final List<String> options;
  final dynamic correctAnswer;

  QuestionData({required this.options, required this.correctAnswer});

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];

    if (json['options'] != null) {
      final optionsList = json['options'] as List;
      parsedOptions = optionsList
          .map(
            (option) =>
                option is Map ? (option['text'] as String) : option.toString(),
          )
          .toList();
    }

    return QuestionData(
      options: parsedOptions,
      correctAnswer: json['correctAnswer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'options': options, 'correctAnswer': correctAnswer};
  }
}

class PostUser {
  final String id;
  final String? username;
  final String? fullName;
  final String? profilePictureUrl;

  PostUser({
    required this.id,
    this.username,
    this.fullName,
    this.profilePictureUrl,
  });

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: json['id'] ?? '',
      username: json['username'],
      fullName: json['fullName'],
      profilePictureUrl: json['profilePictureUrl'],
    );
  }
}

class Post {
  final String id;
  final String text;
  final PostType postType;
  final String? imageUrl;
  final QuestionType? questionType;
  final String? questionText;
  final QuestionData? questionData;
  final int answersCount;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool hasAnswered;
  final bool userIsCorrect;
  final double correctPercentage;
  final PostUser user;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.text,
    required this.postType,
    this.imageUrl,
    this.questionType,
    this.questionText,
    this.questionData,
    required this.answersCount,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.hasAnswered,
    required this.userIsCorrect,
    required this.correctPercentage,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      postType: PostType.fromString(json['postType'] ?? 'text'),
      imageUrl: json['imageUrl'],
      questionType: json['questionType'] != null
          ? QuestionType.fromString(json['questionType'])
          : null,
      questionText: json['questionText'],
      questionData: json['questionData'] != null
          ? QuestionData.fromJson(json['questionData'])
          : null,
      answersCount: json['answersCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      hasAnswered: json['hasAnswered'] ?? false,
      userIsCorrect: json['userIsCorrect'] ?? false,
      correctPercentage: (json['correctPercentage'] ?? 0).toDouble(),
      user: PostUser.fromJson(json['user'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class AnswerResult {
  final bool isCorrect;
  final dynamic correctAnswer;
  final int answersCount;
  final double correctPercentage;

  AnswerResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.answersCount,
    required this.correctPercentage,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      isCorrect: json['isCorrect'] ?? false,
      correctAnswer: json['correctAnswer'],
      answersCount: json['answersCount'] ?? 0,
      correctPercentage: (json['correctPercentage'] ?? 0).toDouble(),
    );
  }
}
