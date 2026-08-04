class RoomParticipant {
  final String userId;
  final String name;
  final String avatar;
  final int score;

  RoomParticipant({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.score,
  });

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'User',
      avatar: json['avatar'] ?? '',
      score: json['score'] ?? 0,
    );
  }
}

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
}

class RoomModel {
  final String id;
  final String code;
  final String title;
  final String topic;
  final String description;
  final String subjectTag;
  final bool isPublic;
  final String hostId;
  final List<RoomParticipant> participants;
  final List<QuizQuestion> questions;
  final bool isQuizActive;

  RoomModel({
    required this.id,
    required this.code,
    required this.title,
    required this.topic,
    required this.description,
    required this.subjectTag,
    required this.isPublic,
    required this.hostId,
    required this.participants,
    required this.questions,
    required this.isQuizActive,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    var rawParticipants = json['participants'] as List? ?? [];
    List<RoomParticipant> parts = rawParticipants.map((p) => RoomParticipant.fromJson(p)).toList();

    var rawQuiz = json['currentQuiz'] ?? {};
    var rawQuestions = rawQuiz['questions'] as List? ?? [];
    List<QuizQuestion> qList = rawQuestions.map((q) => QuizQuestion.fromJson(q)).toList();

    final topicText = json['topic'] ?? '';

    return RoomModel(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? (topicText.isNotEmpty ? topicText : "Study Room"),
      topic: topicText,
      description: json['description'] ?? '',
      subjectTag: json['subjectTag'] ?? 'General',
      isPublic: json['isPublic'] ?? false,
      hostId: json['hostId'] ?? '',
      participants: parts,
      questions: qList,
      isQuizActive: rawQuiz['isActive'] ?? false,
    );
  }
}
