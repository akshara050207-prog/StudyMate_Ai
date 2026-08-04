class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };
}

class Flashcard {
  final String front;
  final String back;

  Flashcard({required this.front, required this.back});

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: json['front'] ?? '',
      back: json['back'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'front': front,
        'back': back,
      };
}

class MaterialModel {
  final String id;
  final String title;
  final String sourceType;
  final String summary;
  final String structuredNotes;
  final List<QuizQuestion> quiz;
  final List<Flashcard> flashcards;
  final DateTime createdAt;

  MaterialModel({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.summary,
    required this.structuredNotes,
    required this.quiz,
    required this.flashcards,
    required this.createdAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Study Material',
      sourceType: json['sourceType'] ?? 'text',
      summary: json['summary'] ?? '',
      structuredNotes: json['structuredNotes'] ?? '',
      quiz: (json['quiz'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q))
              .toList() ??
          [],
      flashcards: (json['flashcards'] as List<dynamic>?)
              ?.map((f) => Flashcard.fromJson(f))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
