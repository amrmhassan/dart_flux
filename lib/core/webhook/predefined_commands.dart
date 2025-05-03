import 'dart:io';

/// Class containing predefined command sets for different deployment operations
class PredefinedCommands {
  /// Commands for updating a Dart project
  static const List<String> dartProjectUpdate = [
    'git fetch origin main',
    'git reset --hard origin/main',
    'dart pub get',
  ];

  /// Commands for building and deploying a Flutter web project
  static List<String> flutterWebBuild() => [
    'git fetch origin main',
    'git reset --hard origin/main',
    'flutter pub get',
    'flutter build web',
  ];

  /// Commands for restarting a Dart server based on the platform
  static List<String> dartServerRestart() =>
      Platform.isLinux
          ? ['sudo systemctl restart dart-server']
          : Platform.isWindows
          ? [
            'taskkill /F /FI "WINDOWTITLE eq dart-server"',
            'start "dart-server" /B dart run main.dart',
          ]
          : Platform.isMacOS
          ? ['pkill -f "dart.*main.dart"', 'dart run main.dart &']
          : throw Exception('Unsupported platform');

  /// Commands for updating dependencies only
  static List<String> updateDependencies() => [
    'dart pub upgrade',
    'dart pub get',
  ];

  /// Commands for running tests
  static List<String> runTests() => ['dart test'];

  /// Commands for analyzing the project
  static List<String> analyzeProject() => ['dart analyze'];

  /// Commands for cleaning and rebuilding
  static List<String> cleanAndRebuild() => [
    'dart clean',
    'dart pub get',
    'dart run build_runner build --delete-conflicting-outputs',
  ];
}
