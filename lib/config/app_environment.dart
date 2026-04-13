/// Environment Configuration for SmartCanteen App
///
/// This file allows easy switching between local development and production environments
/// WITHOUT modifying code or rebuilding the app.

class AppEnvironment {
  /// Set this to true to use local backend (http://localhost:3000)
  /// Set this to false to use production backend (Render)
  ///
  /// This is the ONLY line you need to change when switching environments!
  static const bool USE_LOCAL_BACKEND = false;

  /// Local development server (your computer)
  static const String LOCAL_API_URL = 'http://localhost:3000/api';

  /// Production server (Render)
  static const String PRODUCTION_API_URL =
      'https://smartecanteen-1.onrender.com/api';

  /// Get the appropriate API URL based on environment setting
  static String get apiBaseUrl =>
      USE_LOCAL_BACKEND ? LOCAL_API_URL : PRODUCTION_API_URL;

  /// Get the server base URL (for static files like images)
  static String get serverBaseUrl => apiBaseUrl.replaceAll('/api', '');

  /// Get environment name for logging
  static String get environmentName =>
      USE_LOCAL_BACKEND ? 'LOCAL DEVELOPMENT' : 'PRODUCTION';

  /// Get environment description for debugging
  static String get environmentDescription =>
      'Environment: $environmentName\nAPI URL: $apiBaseUrl';

  /// Print environment info to console (useful for debugging)
  static void printEnvironmentInfo() {
    print('╔════════════════════════════════════════════════════╗');
    print('║  SmartCanteen App Configuration                  ║');
    print('╠════════════════════════════════════════════════════╣');
    print('║  $environmentDescription');
    print('╚════════════════════════════════════════════════════╝');
  }
}
