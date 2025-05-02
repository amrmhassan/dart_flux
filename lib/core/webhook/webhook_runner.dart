import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/webhook/deploy_script.dart';
import 'package:dart_flux/core/errors/server_error.dart';

class WebhookRunner {
  final FluxRequest request;
  final String? branch;
  final String? event;
  final String projectPath;

  WebhookRunner(
    this.request, {
    this.branch = 'refs/heads/main',
    this.event = 'push',
    String? projectPath,
  }) : projectPath = projectPath ?? Directory.current.path;

  File? _scriptFile;

  Future<FluxResponse> hit() async {
    try {
      // Validate webhook event
      final eventType = request.headers['x-github-event']?.firstOrNull;
      if (eventType == null) {
        return request.response.badRequest('Missing x-github-event header');
      }
      if (eventType != event) {
        return request.response.badRequest('Event $eventType is not $event');
      }

      // Parse and validate webhook payload
      final data = await request.asJson;
      final ref = data['ref'] as String?;
      if (ref == null) {
        return request.response.badRequest('Missing ref header');
      }
      if (ref != branch) {
        return request.response.badRequest(
          'Push was to $ref, not $branch - ignoring',
        );
      }

      // Create and execute platform-specific script
      await _createExecutableFile();
      if (_scriptFile == null) {
        throw ServerError('Failed to create script file');
      }

      await _setFilePermissions(_scriptFile!);
      final scriptContent = DeployScript.generateScript(projectPath);
      await _scriptFile!.writeAsString(scriptContent);

      final result = await _executeScript();
      return request.response.data({
        'status': 'success',
        'output': result.stdout,
        'error': result.stderr,
      });
    } catch (e) {
      await _cleanup();
      return request.response.error({'error': e.toString()});
    } finally {
      await _cleanup();
    }
  }

  Future<ProcessResult> _executeScript() async {
    if (_scriptFile == null) throw ServerError('Script file not created');

    if (Platform.isWindows) {
      return Process.run('cmd.exe', ['/c', _scriptFile!.path]);
    } else {
      return Process.run('/bin/bash', [_scriptFile!.path]);
    }
  }

  Future<void> _setFilePermissions(File file) async {
    if (!Platform.isWindows) {
      // Set execute permissions on Unix-like systems (755)
      await Process.run('chmod', ['+x', file.path]);
    }
  }

  Future<void> _createExecutableFile() async {
    final extension = Platform.isWindows ? '.bat' : '.sh';
    final fileName = '${dartID.generate()}$extension';
    final filePath = path.join(Directory.systemTemp.path, fileName);

    _scriptFile = File(filePath);

    if (await _scriptFile!.exists()) {
      await _scriptFile!.delete();
    }

    await _scriptFile!.create();
  }

  Future<void> _cleanup() async {
    try {
      if (_scriptFile != null && await _scriptFile!.exists()) {
        await _scriptFile!.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}
