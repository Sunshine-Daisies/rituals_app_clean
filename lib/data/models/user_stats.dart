class UserStats {
  final int totalRituals;
  final int completedToday;
  final int totalCompletions;
  final int longestStreak;
  final int currentBestStreak;
  final List<WeeklyActivity> weeklyActivity;
  final List<TopRitual> topRituals;
  final List<MonthlyActivity> monthlyActivity;

  UserStats({
    required this.totalRituals,
    required this.completedToday,
    required this.totalCompletions,
    required this.longestStreak,
    required this.currentBestStreak,
    required this.weeklyActivity,
    required this.topRituals,
    required this.monthlyActivity,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRituals: json['totalRituals'] ?? 0,
      completedToday: json['completedToday'] ?? 0,
      totalCompletions: json['totalCompletions'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      currentBestStreak: json['currentBestStreak'] ?? 0,
      weeklyActivity: (json['weeklyActivity'] as List?)
              ?.map((e) => WeeklyActivity.fromJson(e))
              .toList() ??
          [],
      topRituals: (json['topRituals'] as List?)
              ?.map((e) => TopRitual.fromJson(e))
              .toList() ??
          [],
      monthlyActivity: (json['monthlyActivity'] as List?)
              ?.map((e) => MonthlyActivity.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class WeeklyActivity {
  final String day;
  final int count;

  WeeklyActivity({required this.day, required this.count});

  factory WeeklyActivity.fromJson(Map<String, dynamic> json) {
    return WeeklyActivity(
      day: json['day'] ?? '',
      count: int.tryParse(json['count'].toString()) ?? 0,
    );
  }
}

class MonthlyActivity {
  final DateTime date;
  final int count;

  MonthlyActivity({required this.date, required this.count});

  factory MonthlyActivity.fromJson(Map<String, dynamic> json) {
    return MonthlyActivity(
      date: DateTime.parse(json['date']),
      count: int.tryParse(json['count'].toString()) ?? 0,
    );
  }
}

class TopRitual {
  final String name;
  final int count;
  final int currentStreak;

  TopRitual({
    required this.name, 
    required this.count,
    required this.currentStreak,
  });

  factory TopRitual.fromJson(Map<String, dynamic> json) {
    return TopRitual(
      name: json['name'] ?? '',
      count: int.tryParse(json['count'].toString()) ?? 0,
      currentStreak: int.tryParse(json['current_streak'].toString()) ?? 0,
    );
  }
}
