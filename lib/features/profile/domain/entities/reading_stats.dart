/// Aggregated reading metrics and weekly activity breakdown.
class ReadingStats {
  final int totalBooksOpened;
  final int totalBooksCompleted;
  final int totalChaptersRead;
  final int totalMinutesRead;
  final int totalMinutesListened;
  final int currentStreakDays;
  final int longestStreakDays;
  final int dailyGoalMinutes;
  final int todayMinutesCompleted;
  final List<DayActivity> weeklyActivity;

  const ReadingStats({
    this.totalBooksOpened = 8,
    this.totalBooksCompleted = 4,
    this.totalChaptersRead = 36,
    this.totalMinutesRead = 420,
    this.totalMinutesListened = 390,
    this.currentStreakDays = 5,
    this.longestStreakDays = 14,
    this.dailyGoalMinutes = 30,
    this.todayMinutesCompleted = 25,
    this.weeklyActivity = const [
      DayActivity(dayName: 'Mon', minutes: 35, completed: true),
      DayActivity(dayName: 'Tue', minutes: 40, completed: true),
      DayActivity(dayName: 'Wed', minutes: 25, completed: true),
      DayActivity(dayName: 'Thu', minutes: 45, completed: true),
      DayActivity(dayName: 'Fri', minutes: 30, completed: true),
      DayActivity(dayName: 'Sat', minutes: 0, completed: false),
      DayActivity(dayName: 'Sun', minutes: 25, completed: true),
    ],
  });

  double get totalHoursRead => (totalMinutesRead / 60.0);
  double get totalHoursListened => (totalMinutesListened / 60.0);
  double get dailyGoalProgress => (todayMinutesCompleted / dailyGoalMinutes).clamp(0.0, 1.0);
}

class DayActivity {
  final String dayName;
  final int minutes;
  final bool completed;

  const DayActivity({
    required this.dayName,
    required this.minutes,
    required this.completed,
  });

  Map<String, dynamic> toMap() => {
        'dayName': dayName,
        'minutes': minutes,
        'completed': completed,
      };

  factory DayActivity.fromMap(Map<String, dynamic> map) {
    return DayActivity(
      dayName: map['dayName'] as String? ?? 'Mon',
      minutes: (map['minutes'] as num?)?.toInt() ?? 0,
      completed: map['completed'] as bool? ?? false,
    );
  }
}
