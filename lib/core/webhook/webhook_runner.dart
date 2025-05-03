import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/webhook/deploy_script.dart';
import 'package:dart_flux/core/errors/server_error.dart';

class WebhookRunner {
  final FluxRequest request;
  final String branch;
  final String event;
  final String projectPath;
  final List<String> runCommand;
  final Duration timeout;
  final int maxRetries;
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
  }) : projectPath = projectPath ?? Directory.current.path,
       event = event ?? 'push',
       branch = branch ?? 'refs/heads/main',
       timeout = timeout ?? const Duration(minutes: 30);

  File? _scriptFile;

  Future<FluxResponse> hit() async {
    if (_isExecuting) {
      return request.response.error({
        'status': 'error',
        'message': 'Another webhook execution is already in progress',
      });
    }

    _isExecuting = true;
    try {
      if (runCommand.isEmpty) {
        return request.response.badRequest('No commands provided to execute');
      }

      // Validate project path
      if (!await Directory(projectPath).exists()) {
        return request.response.badRequest(
          'Project directory does not exist: $projectPath',
        );
      }

      // Validate webhook event
      final eventType = request.headers['x-github-event']?.firstOrNull;
      if (eventType == null) {
        return request.response.badRequest('Missing x-github-event header');
      }
      if (eventType != event) {
        return request.response.badRequest('Event $eventType is not $event');
      }

      // Parse and validate webhook payload
      Map<String, dynamic>? data;
      try {
        data = await request.asJson;
      } catch (e) {
        return request.response.badRequest('Invalid JSON payload');
      }

      if (data is! Map<String, dynamic>) {
        return request.response.badRequest('Invalid webhook payload format');
      }

      final ref = data['ref'];
      if (ref is! String) {
        return request.response.badRequest('Missing or invalid ref in payload');
      }
      if (ref != branch) {
        return request.response.badRequest(
          'Push was to $ref, not $branch - ignoring',
        );
      }

      // Create and execute platform-specific script
      try {
        await _createExecutableFile();
      } catch (e) {
        throw ServerError('Failed to create script file: ${e.toString()}');
      }

      if (_scriptFile == null) {
        throw ServerError('Failed to create script file');
      }

      try {
        await _setFilePermissions(_scriptFile!);
      } catch (e) {
        throw ServerError('Failed to set script permissions: ${e.toString()}');
      }

      final scriptContent = DeployScript.generateScript(
        projectPath,
        runCommand,
      );

      try {
        await _scriptFile!.writeAsString(scriptContent);
      } catch (e) {
        throw ServerError('Failed to write script content: ${e.toString()}');
      }

      ProcessResult? result;
      ServerError? lastError;
      int attemptsMade = 0;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        attemptsMade = attempt;
        try {
          result = await _executeScript().timeout(
            timeout,
            onTimeout: () {
              throw ServerError(
                'Script execution timed out after ${timeout.inMinutes} minutes',
              );
            },
          );
          break; // Success, exit retry loop
        } catch (e) {
          lastError = e is ServerError ? e : ServerError(e.toString());
          if (attempt == maxRetries) {
            throw lastError;
          }
          await Future.delayed(_defaultRetryDelay * attempt);
          continue;
        }
      }

      if (result == null) {
        throw lastError ?? ServerError('Script execution failed');
      }

      if (result.exitCode != 0) {
        return request.response.error({
          'status': 'error',
          'message': 'Script execution failed',
          'output': result.stdout,
          'error': result.stderr,
          'exitCode': result.exitCode,
          'attempts': attemptsMade,
        });
      }

      return request.response.data({
        'status': 'success',
        'output': result.stdout,
        'error': result.stderr,
        'exitCode': result.exitCode,
        'attempts': attemptsMade,
      });
    } catch (e) {
      return request.response.error({
        'status': 'error',
        'message': e.toString(),
      });
    } finally {
      _isExecuting = false;
      await _cleanup();
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
      }
    } catch (e) {
      // Log cleanup error but don't rethrow as it's not critical
      print('Warning: Failed to cleanup webhook script file: ${e.toString()}');
    }
  }
}
