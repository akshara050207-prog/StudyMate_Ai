class DailyActivity {
  final String day;
  final double minutesStudied;
  final int quizzesTaken;

  DailyActivity({
    required this.day,
    required this.minutesStudied,
    required this.quizzesTaken,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      day: json['day'] ?? 'Mon',
      minutesStudied: (json['minutesStudied'] ?? 0).toDouble(),
      quizzesTaken: json['quizzesTaken'] ?? 0,
    );
  }
}

class StreakModel {
  final int currentStreak;
  final int highestStreak;
  final List<DailyActivity> weeklyActivity;

  StreakModel({
    required this.currentStreak,
    required this.highestStreak,
    required this.weeklyActivity,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['weeklyActivity'] as List? ?? [];
    List<DailyActivity> list = rawList.map((a) => DailyActivity.fromJson(a)).toList();

    return StreakModel(
      currentStreak: json['currentStreak'] ?? 1,
      highestStreak: json['highestStreak'] ?? 1,
      weeklyActivity: list.isNotEmpty
          ? list
          : [
              DailyActivity(day: 'Mon', minutesStudied: 25, quizzesTaken: 2),
              DailyActivity(day: 'Tue', minutesStudied: 40, quizzesTaken: 3),
              DailyActivity(day: 'Wed', minutesStudied: 60, quizzesTaken: 4),
              DailyActivity(day: 'Thu', minutesStudied: 30, quizzesTaken: 1),
              DailyActivity(day: 'Fri', minutesStudied: 45, quizzesTaken: 3),
              DailyActivity(day: 'Sat', minutesStudied: 15, quizzesTaken: 0),
              DailyActivity(day: 'Sun', minutesStudied: 50, quizzesTaken: 2),
            ],
    );
  }
}
