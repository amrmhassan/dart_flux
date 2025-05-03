import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/webhook/predefined_commands.dart';
import 'package:dart_flux/core/webhook/webhook_runner.dart';

/// Handles GitHub webhook requests by executing specified commands
/// when a push event occurs on a specified branch.
///
/// Example usage:
/// ```dart
/// final handler = WebhookHandler(
///   branch: 'refs/heads/main',
///   event: 'push',
///   runCommand: ['git pull', 'dart pub get'],
///   timeout: Duration(minutes: 5),
///   maxRetries: 3,
/// );
/// ```
class WebhookHandler {
  /// The Git branch to monitor (e.g., 'refs/heads/main')
  final String? branch;

  /// The webhook event to listen for (e.g., 'push')
  final String? event;

  /// The project directory path where commands will be executed
  final String? projectPath;

  /// List of commands to execute when the webhook is triggered
  final List<String> runCommand;

  /// Maximum time allowed for command execution
  final Duration? timeout;

  /// Number of times to retry failed commands
  final int maxRetries;

  WebhookHandler({
    this.branch,
    this.event,
    this.projectPath,
    this.runCommand = PredefinedCommands.dartProjectUpdate,
    this.timeout,
    this.maxRetries = 3,
  });

  /// Returns a handler function that can be used with the routing system
  ProcessorHandler get handler => (request, response, pathArgs) async {
    var runner = WebhookRunner(
      request,
      projectPath: projectPath,
      event: event,
      branch: branch,
      runCommand: runCommand,
      timeout: timeout,
      maxRetries: maxRetries,
    );
    var output = await runner.hit();
    return output;
  };
}
