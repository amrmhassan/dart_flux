import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/webhook/predefined_commands.dart';
import 'package:dart_flux/core/webhook/webhook_runner.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/webhook/models/webhook_secret.dart';

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
///   secret: WebhookSecret(secret: 'your-webhook-secret'),
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

  /// Optional webhook secret for request validation
  final WebhookSecret? secret;

  /// Whether to run commands concurrently (default: false)
  final bool concurrent;

  WebhookHandler({
    this.branch,
    this.event,
    this.projectPath,
    this.runCommand = PredefinedCommands.dartProjectUpdate,
    this.timeout,
    this.maxRetries = 3,
    this.secret,
    this.concurrent = false,
  }) {
    if (runCommand.isEmpty) {
      throw ServerError('At least one command must be provided');
    }
  }

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
      secret: secret,
      concurrent: concurrent,
    );
    var output = await runner.hit();
    return output;
  };
}
