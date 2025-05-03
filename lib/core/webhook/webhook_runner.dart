import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/webhook/deploy_script.dart';
import 'package:dart_flux/core/webhook/models/webhook_secret.dart';
import 'package:dart_flux/core/webhook/utils/webhook_logger.dart';
import 'package:dart_flux/core/errors/server_error.dart';

/// Class responsible for executing webhook operations based on received HTTP requests.
class WebhookRunner {
  final FluxRequest request;
  final String branch;
  final String event;
  final String projectPath;
  final List<String> runCommand;
  final Duration timeout;
  final int maxRetries;
  final WebhookSecret? secret;
  final bool concurrent;
  late final WebhookLogger _logger;
  static const _defaultRetryDelay = Duration(seconds: 5);
  bool _isExecuting = false;
  bool _isCleanedUp = false;

  WebhookRunner(
    this.request, {
    String? branch,
    String? event,
    String? projectPath,
    required this.runCommand,
    Duration? timeout,
    this.maxRetries = 3,
    this.secret,
    this.concurrent = false,
  }) : projectPath = projectPath ?? Directory.current.path,
       event = event ?? 'push',
       branch = branch ?? 'refs/heads/main',
       timeout = timeout ?? const Duration(minutes: 30) {
    _logger = WebhookLogger(
      logPath: path.join(this.projectPath, 'logs', 'webhook.log'),
    );
  }

  File? _scriptFile;

  /// Processes the webhook request and executes the configured commands
  Future<FluxResponse> hit() async {
    if (_isExecuting) {
      await _logger.warning('Another webhook execution is already in progress');
      return request.response.error({
        'status': 'error',
        'message': 'Another webhook execution is already in progress',
      });
    }

    _isExecuting = true;
    await _logger.info('Starting webhook execution');

    try {
      if (runCommand.isEmpty) {
        await _logger.error('No commands provided to execute');
        return request.response.badRequest('No commands provided to execute');
      }

      // Validate webhook secret if provided
      if (secret != null) {
        await _logger.info('Validating webhook signature');
        final isValid = await _validateWebhookSecret();
        if (!isValid) {
          await _logger.error('Invalid webhook signature');
          return request.response.unauthorized('Invalid webhook signature');
        }
        await _logger.info('Webhook signature validated successfully');
      }

      // Validate project path
      await _logger.info('Validating project path: $projectPath');
      if (!await Directory(projectPath).exists()) {
        await _logger.error('Project directory does not exist: $projectPath');
        return request.response.badRequest(
          'Project directory does not exist: $projectPath',
        );
      }

      // Validate webhook event
      final eventType = request.headers['x-github-event']?.firstOrNull;
      await _logger.info('Received event: $eventType');
      if (eventType == null) {
        await _logger.error('Missing x-github-event header');
        return request.response.badRequest('Missing x-github-event header');
      }
      if (eventType != event) {
        await _logger.warning('Event $eventType is not $event - ignoring');
        return request.response.badRequest('Event $eventType is not $event');
      }

      // Parse and validate webhook payload
      Map<String, dynamic>? data;
      try {
        await _logger.info('Parsing webhook payload');
        data = await request.asJson;
      } catch (e) {
        await _logger.error('Invalid JSON payload: ${e.toString()}');
        return request.response.badRequest('Invalid JSON payload');
      }

      if (data is! Map<String, dynamic>) {
        await _logger.error('Invalid webhook payload format');
        return request.response.badRequest('Invalid webhook payload format');
      }

      final ref = data['ref'];
      await _logger.info('Push event for ref: $ref');
      if (ref is! String) {
        await _logger.error('Missing or invalid ref in payload');
        return request.response.badRequest('Missing or invalid ref in payload');
      }
      if (ref != branch) {
        await _logger.warning('Push was to $ref, not $branch - ignoring');
        return request.response.badRequest(
          'Push was to $ref, not $branch - ignoring',
        );
      }

      // Create and execute platform-specific script
      try {
        await _logger.info('Creating executable script file');
        await _createExecutableFile();
      } catch (e) {
        await _logger.error('Failed to create script file: ${e.toString()}');
        throw ServerError('Failed to create script file: ${e.toString()}');
      }

      if (_scriptFile == null) {
        await _logger.error('Failed to create script file');
        throw ServerError('Failed to create script file');
      }

      try {
        await _logger.info('Setting file permissions');
        await _setFilePermissions(_scriptFile!);
      } catch (e) {
        await _logger.error(
          'Failed to set script permissions: ${e.toString()}',
        );
        throw ServerError('Failed to set script permissions: ${e.toString()}');
      }

      await _logger.info(
        'Generating script content with ${runCommand.length} commands',
      );
      final scriptContent = DeployScript.generateScript(
        projectPath,
        concurrent ? _wrapCommandsForConcurrency(runCommand) : runCommand,
      );

      try {
        await _logger.info('Writing script content');
        await _scriptFile!.writeAsString(scriptContent);
      } catch (e) {
        await _logger.error('Failed to write script content: ${e.toString()}');
        throw ServerError('Failed to write script content: ${e.toString()}');
      }

      ProcessResult? result;
      ServerError? lastError;
      int attemptsMade = 0;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        attemptsMade = attempt;
        try {
          await _logger.info(
            'Executing script (attempt $attempt of $maxRetries)',
          );
          result = await _executeScript().timeout(
            timeout,
            onTimeout: () {
              _logger.error(
                'Script execution timed out after ${timeout.inMinutes} minutes',
              );
              throw ServerError(
                'Script execution timed out after ${timeout.inMinutes} minutes',
              );
            },
          );
          await _logger.info('Script executed successfully');
          break; // Success, exit retry loop
        } catch (e) {
          lastError = e is ServerError ? e : ServerError(e.toString());
          await _logger.error(
            'Script execution failed: ${lastError.toString()}',
          );
          if (attempt == maxRetries) {
            throw lastError;
          }
          await _logger.info(
            'Retrying in ${_defaultRetryDelay * attempt} seconds',
          );
          await Future.delayed(_defaultRetryDelay * attempt);
          continue;
        }
      }

      if (result == null) {
        await _logger.error('Script execution failed completely');
        throw lastError ?? ServerError('Script execution failed');
      }

      if (result.exitCode != 0) {
        await _logger.error(
          'Script execution failed with exit code ${result.exitCode}',
        );
        return request.response.error({
          'status': 'error',
          'message': 'Script execution failed',
          'output': result.stdout,
          'error': result.stderr,
          'exitCode': result.exitCode,
          'attempts': attemptsMade,
        });
      }

      await _logger.info('Webhook executed successfully');
      return request.response.data({
        'status': 'success',
        'output': result.stdout,
        'error': result.stderr,
        'exitCode': result.exitCode,
        'attempts': attemptsMade,
      });
    } catch (e) {
      await _logger.error('Webhook execution error: ${e.toString()}');
      return request.response.error({
        'status': 'error',
        'message': e.toString(),
      });
    } finally {
      _isExecuting = false;
      await _cleanup();
    }
  }

  List<String> _wrapCommandsForConcurrency(List<String> commands) {
    if (Platform.isWindows) {
      return ['start /B cmd /C "${commands.join(' && ')}"'];
    } else {
      return ['(' + commands.join(' & ') + ') &'];
    }
  }

  Future<bool> _validateWebhookSecret() async {
    if (secret == null) return true;

    final signature = request.headers[secret!.headerName]?.firstOrNull;
    if (signature == null) return false;

    try {
      final payload = await request.asBytes;
      final hmac = Hmac(sha256, utf8.encode(secret!.secret));
      final digest = hmac.convert(payload);
      final computedSignature = 'sha256=${digest.toString()}';

      return signature == computedSignature;
    } catch (e) {
      await _logger.error(
        'Error validating webhook signature: ${e.toString()}',
      );
      return false;
    }
  }

  Future<ProcessResult> _executeScript() async {
    if (_scriptFile == null) throw ServerError('Script file not created');
    if (!await _scriptFile!.exists())
      throw ServerError('Script file does not exist');

    try {
      if (Platform.isWindows) {
        return Process.run(
          'cmd.exe',
          ['/c', _scriptFile!.path],
          stdoutEncoding: systemEncoding,
          stderrEncoding: systemEncoding,
        );
      } else {
        return Process.run(
          '/bin/bash',
          [_scriptFile!.path],
          stdoutEncoding: systemEncoding,
          stderrEncoding: systemEncoding,
        );
      }
    } catch (e) {
      throw ServerError('Failed to execute script: ${e.toString()}');
    }
  }

  Future<void> _setFilePermissions(File file) async {
    if (!Platform.isWindows) {
      try {
        final result = await Process.run('chmod', ['+x', file.path]);
        if (result.exitCode != 0) {
          throw ServerError(
            'Failed to set execute permissions: ${result.stderr}',
          );
        }
      } catch (e) {
        throw ServerError('Failed to set file permissions: ${e.toString()}');
      }
    }
  }

  Future<void> _createExecutableFile() async {
    final extension = Platform.isWindows ? '.bat' : '.sh';
    final fileName = '${dartID.generate()}$extension';
    final filePath = path.join(Directory.systemTemp.path, fileName);

    try {
      _scriptFile = File(filePath);

      if (await _scriptFile!.exists()) {
        await _scriptFile!.delete();
      }

      await _scriptFile!.create();
    } catch (e) {
      throw ServerError('Failed to create executable file: ${e.toString()}');
    }
  }

  Future<void> _cleanup() async {
    if (_isCleanedUp) return;
    _isCleanedUp = true;

    try {
      if (_scriptFile != null) {
        final file = _scriptFile;
        _scriptFile = null;
        if (await file!.exists()) {
          await file.delete();
        }
        await _logger.info('Cleaned up temporary script files');
      }
    } catch (e) {
      await _logger.warning(
        'Failed to cleanup webhook script file: ${e.toString()}',
      );
    }
  }
}
