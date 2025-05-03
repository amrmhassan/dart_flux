import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_flux/core/errors/server_error.dart';

class DeployScript {
  static String generateScript(String projectPath, List<String> commands) {
    if (commands.isEmpty) {
      throw ServerError('No commands provided for script generation');
    }

    // Sanitize commands to prevent script injection
    commands = commands.map(_sanitizeCommand).toList();

    if (Platform.isLinux) return _generateLinuxScript(projectPath, commands);
    if (Platform.isWindows)
      return _generateWindowsScript(projectPath, commands);
    if (Platform.isMacOS) return _generateMacScript(projectPath, commands);
    throw ServerError(
      '${Platform.operatingSystem} is not supported for webhooks',
    );
  }

  static String _sanitizeCommand(String command) {
    // Remove any potentially harmful characters or sequences
    command = command.replaceAll(RegExp(r'[;&|]'), ' ');
    return command.trim();
  }

  static String _generateLinuxScript(
    String projectPath,
    List<String> commands,
  ) {
    final logPath = path.join(projectPath, 'deploy-log.txt');
    final commandsStr = commands
        .map(
          (cmd) => '''
# Execute command with error handling
echo "\$(date) - Running command: $cmd" >> "\$LOG_FILE"
if ! $cmd >> "\$LOG_FILE" 2>&1; then
  echo "\$(date) - Command failed: $cmd" >> "\$LOG_FILE"
  exit 1
fi
echo "\$(date) - Command completed successfully: $cmd" >> "\$LOG_FILE"
''',
        )
        .join('\n');

    return """#!/bin/bash
set -e

# Ensure the PATH includes directories for git and other common binaries
export PATH=\$PATH:/usr/bin:/usr/local/bin

LOG_FILE="$logPath"

# Delete the log file if it exists
if [ -f "\$LOG_FILE" ]; then
  rm "\$LOG_FILE"
fi

echo "\$(date) - Script started" >> "\$LOG_FILE"

# Create a trap to handle errors and cleanup
trap 'echo "\$(date) - Script failed" >> "\$LOG_FILE"' ERR

# Navigate to the project directory
cd "$projectPath" || {
  echo "\$(date) - Failed to change to project directory" >> "\$LOG_FILE"
  exit 1
}
echo "\$(date) - Changed to project directory" >> "\$LOG_FILE"

# Execute all commands with error handling
$commandsStr

echo "\$(date) - Script completed successfully" >> "\$LOG_FILE"
""";
  }

  static String _generateWindowsScript(
    String projectPath,
    List<String> commands,
  ) {
    final logPath = path.join(projectPath, 'deploy-log.txt');
    final commandsStr = commands
        .map(
          (cmd) => '''
:: Execute command with error handling
echo %date% %time% - Running command: $cmd >> "%LOG_FILE%"
$cmd >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - Command failed: $cmd >> "%LOG_FILE%"
    exit /b 1
)
echo %date% %time% - Command completed successfully: $cmd >> "%LOG_FILE%"
''',
        )
        .join('\n');

    return """@echo off
setlocal EnableDelayedExpansion

set LOG_FILE=$logPath

if exist "%LOG_FILE%" del "%LOG_FILE%"

echo %date% %time% - Script started >> "%LOG_FILE%"

cd /d "$projectPath"
if %ERRORLEVEL% NEQ 0 (
    echo %date% %time% - Failed to change to project directory >> "%LOG_FILE%"
    exit /b 1
)
echo %date% %time% - Changed to project directory >> "%LOG_FILE%"

:: Execute all commands with error handling
$commandsStr

echo %date% %time% - Script completed successfully >> "%LOG_FILE%"
""";
  }

  static String _generateMacScript(String projectPath, List<String> commands) {
    final logPath = path.join(projectPath, 'deploy-log.txt');
    final commandsStr = commands
        .map(
          (cmd) => '''
# Execute command with error handling
echo "\$(date) - Running command: $cmd" >> "\$LOG_FILE"
if ! $cmd >> "\$LOG_FILE" 2>&1; then
  echo "\$(date) - Command failed: $cmd" >> "\$LOG_FILE"
  exit 1
fi
echo "\$(date) - Command completed successfully: $cmd" >> "\$LOG_FILE"
''',
        )
        .join('\n');

    return """#!/bin/bash
set -e

LOG_FILE="$logPath"

# Delete the log file if it exists
[ -f "\$LOG_FILE" ] && rm "\$LOG_FILE"

echo "\$(date) - Script started" >> "\$LOG_FILE"

# Create a trap to handle errors and cleanup
trap 'echo "\$(date) - Script failed" >> "\$LOG_FILE"' ERR

# Navigate to the project directory
cd "$projectPath" || {
  echo "\$(date) - Failed to change to project directory" >> "\$LOG_FILE"
  exit 1
}
echo "\$(date) - Changed to project directory" >> "\$LOG_FILE"

# Execute all commands with error handling
$commandsStr

echo "\$(date) - Script completed successfully" >> "\$LOG_FILE"
""";
  }
}
