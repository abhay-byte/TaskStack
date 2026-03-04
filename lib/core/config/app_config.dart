/// lib/core/config/app_config.dart
///
/// Compile-time configuration resolved from --dart-define=FLAVOUR=<x>
class AppConfig {
  AppConfig._();

  static const flavour =
      String.fromEnvironment('FLAVOUR', defaultValue: 'production');

  static bool get isDev => flavour == 'dev';
  static bool get isStaging => flavour == 'staging';
  static bool get isProduction => flavour == 'production';

  static String get appName => switch (flavour) {
        'dev' => 'TaskStack Dev',
        'staging' => 'TaskStack Staging',
        _ => 'TaskStack',
      };

  static String get databaseName => switch (flavour) {
        'dev' => 'taskstack_dev.db',
        'staging' => 'taskstack_staging.db',
        _ => 'taskstack.db',
      };

  /// REST API base URL — override via --dart-define=API_BASE_URL=...
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://taskstack-api.onrender.com',
  );
}
