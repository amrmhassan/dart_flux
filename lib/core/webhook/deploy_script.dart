import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_flux/core/errors/server_error.dart';

class DeployScript {
  static String generateScript(String projectPath) {
    if (Platform.isLinux) return _generateLinuxScript(projectPath);
    if (Platform.isWindows) return _generateWindowsScript(projectPath);
    if (Platform.isMacOS) return _generateMacScript(projectPath);
    throw ServerError(
      '${Platform.operatingSystem} is not supported for webhooks',
    );
  }

  static String _generateLinuxScript(String projectPath) {
    final logPath = path.join(projectPath, 'deploy-log.txt');
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

# Navigate to the project directory
cd "$projectPath"
echo "\$(date) - Changed to project directory" >> "\$LOG_FILE"

# Pull the latest changes
git fetch origin main >> "\$LOG_FILE" 2>&1
git reset --hard origin/main >> "\$LOG_FILE" 2>&1

# Restart the application (adjust as needed)
if command -v systemctl &> /dev/null; then
    sudo systemctl restart dart-server >> "\$LOG_FILE" 2>&1
else
    # Fallback for systems without systemd
    pkill -f "dart.*main.dart" || true
    nohup dart run main.dart >> "\$LOG_FILE" 2>&1 &
fi

echo "\$(date) - Script completed" >> "\$LOG_FILE"
""";
  }

  static String _generateWindowsScript(String projectPath) {
    final logPath = path.join(projectPath, 'deploy-log.txt');
    return """@echo off
set LOG_FILE=$logPath

if exist "%LOG_FILE%" del "%LOG_FILE%"

echo %date% %time% - Script started >> "%LOG_FILE%"

cd /d "$projectPath"
echo %date% %time% - Changed to project directory >> "%LOG_FILE%"

git fetch origin main >> "%LOG_FILE%" 2>&1
git reset --hard origin/main >> "%LOG_FILE%" 2>&1

:: Kill existing process if running
tasklist /FI "WINDOWTITLE eq dart-server" /NH | find "dart" > nul
if %ERRORLEVEL% EQU 0 (
    taskkill /F /FI "WINDOWTITLE eq dart-server" >> "%LOG_FILE%" 2>&1
)

:: Start the server in a new window
start "dart-server" /B dart run main.dart >> "%LOG_FILE%" 2>&1

echo %date% %time% - Script completed >> "%LOG_FILE%"
""";
  }

  static String _generateMacScript(String projectPath) {
    final logPath = path.join(projectPath, 'deploy-log.txt');
    return """#!/bin/bash
set -e

LOG_FILE="$logPath"

# Delete the log file if it exists
[ -f "\$LOG_FILE" ] && rm "\$LOG_FILE"

echo "\$(date) - Script started" >> "\$LOG_FILE"

# Navigate to the project directory
cd "$projectPath"
echo "\$(date) - Changed to project directory" >> "\$LOG_FILE"

# Pull the latest changes
git fetch origin main >> "\$LOG_FILE" 2>&1
git reset --hard origin/main >> "\$LOG_FILE" 2>&1

# Kill existing process if running
pkill -f "dart.*main.dart" || true

# Start the server
nohup dart run main.dart >> "\$LOG_FILE" 2>&1 &

echo "\$(date) - Script completed" >> "\$LOG_FILE"
""";
  }
}
