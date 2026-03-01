class TaskGraphics {
  /// Defines all the available animated SVG assets for tasks.
  static const List<String> availableGraphics = [
    'assets/images/dashboard_illustration.svg',
    'assets/images/task_gym.svg',
    'assets/images/task_study.svg',
    'assets/images/task_office.svg',
    'assets/images/task_reminder.svg',
    'assets/images/task_wakeup.svg',
    'assets/images/task_focus.svg',
    'assets/images/task_mental.svg',
    'assets/images/task_water.svg',
    'assets/images/task_diet.svg',
    'assets/images/task_shopping.svg',
    'assets/images/task_cleaning.svg',
    'assets/images/task_call.svg',
    'assets/images/task_travel.svg',
    'assets/images/task_coding.svg',
    'assets/images/task_goal.svg',
    'assets/images/task_sleep.svg',
    'assets/images/task_meeting.svg',
    'assets/images/task_learning.svg',
    'assets/images/task_habit.svg',
    'assets/images/task_finance.svg',
  ];

  /// Helper to get a nicely formatted, human-readable name from the path.
  static String getDisplayName(String path) {
    if (path.contains('dashboard')) return 'Dashboard';

    // Extract e.g. "gym" from "assets/images/task_gym.svg"
    final filename = path.split('/').last;
    if (filename.startsWith('task_') && filename.endsWith('.svg')) {
      final title = filename.substring(5, filename.length - 4);
      // Capitalize first letter
      return title.replaceFirst(title[0], title[0].toUpperCase());
    }
    return filename;
  }
}
