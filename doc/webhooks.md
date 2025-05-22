# Webhooks

This guide explains how to use the Webhook functionality in Dart Flux to automate tasks triggered by external events, such as GitHub repository changes.

## Overview

Dart Flux provides built-in support for handling webhook requests from external services like GitHub, GitLab, or custom sources. The webhook system allows you to:

- Listen for webhook events
- Authenticate requests with secrets
- Execute shell commands in response to events
- Control execution flow with timeout and retry settings

## Basic Webhook Setup

Here's how to set up a basic webhook handler for GitHub:

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Create a webhook handler
  final webhookHandler = WebhookHandler(
    // Only respond to push events on the main branch
    branch: 'refs/heads/main',
    event: 'push',
    
    // Commands to run when the webhook is triggered
    runCommand: [
      'git pull origin main',
      'dart pub get',
      'dart run build_runner build --delete-conflicting-outputs',
    ],
    
    // Set a timeout for command execution
    timeout: Duration(minutes: 5),
    
    // Retry settings
    maxRetries: 3,
    
    // Optional webhook secret for authentication
    secret: WebhookSecret(secret: 'your-webhook-secret'),
  );
  
  // Get the handler function to register with your router
  final handler = webhookHandler.handler;
  
  // Create a router with the webhook endpoint
  final router = Router()
    .post('webhook', handler);
  
  // Create and start the server
  final server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
  print('Webhook server running on port 3000');
}
```

## Webhook Configurations

The `WebhookHandler` class provides several configuration options:

```dart
WebhookHandler({
  // Git branch to monitor (e.g., 'refs/heads/main')
  this.branch,
  
  // Webhook event to listen for (e.g., 'push')
  this.event,
  
  // Project directory path where commands will be executed
  this.projectPath,
  
  // List of commands to execute when the webhook is triggered
  this.runCommand = PredefinedCommands.dartProjectUpdate,
  
  // Maximum time allowed for command execution
  this.timeout,
  
  // Number of times to retry failed commands
  this.maxRetries = 3,
  
  // Optional webhook secret for request validation
  this.secret,
  
  // Whether to run commands concurrently
  this.concurrent = false,
});
```

## Using Predefined Commands

Dart Flux comes with predefined command lists for common tasks:

```dart
// Use predefined commands for updating a Dart project
final webhookHandler = WebhookHandler(
  branch: 'refs/heads/main',
  event: 'push',
  runCommand: PredefinedCommands.dartProjectUpdate,
);

// PredefinedCommands.dartProjectUpdate includes:
// [
//   'git pull',
//   'dart pub get',
// ]

// Other predefined command lists:
// - PredefinedCommands.flutterProjectUpdate
// - PredefinedCommands.nodeProjectUpdate
```

## Webhook Security

For security, you should validate webhook requests using a secret:

```dart
// Create a webhook secret
final secret = WebhookSecret(
  secret: 'your-shared-secret',
  
  // Optional: specify the header field containing the signature
  headerKey: 'X-Hub-Signature-256',
  
  // Optional: specify the algorithm used for the signature
  algorithm: 'sha256',
);

// Use the secret in your webhook handler
final webhookHandler = WebhookHandler(
  secret: secret,
  runCommand: ['git pull', 'dart pub get'],
);
```

### GitHub Webhook Setup

When configuring a webhook in GitHub:

1. Go to your repository settings
2. Click on "Webhooks" → "Add webhook"
3. Set the Payload URL to your server's webhook endpoint (e.g., `https://example.com/webhook`)
4. Set Content type to `application/json`
5. Enter your secret in the "Secret" field
6. Choose which events should trigger the webhook (e.g., just the `push` event)
7. Click "Add webhook"

## Controlling Execution Flow

You can control how commands are executed:

```dart
// Run commands one after another (default behavior)
final sequentialHandler = WebhookHandler(
  runCommand: [
    'git pull',
    'dart pub get',
    'dart run build_runner build',
  ],
  concurrent: false, // This is the default
);

// Run all commands concurrently
final concurrentHandler = WebhookHandler(
  runCommand: [
    'backup-database.sh',
    'optimize-images.sh',
    'generate-sitemap.sh',
  ],
  concurrent: true,
);
```

## Advanced Webhook Handler

This example shows a more advanced webhook setup:

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';

void main() async {
  // Set up different handlers for different branches
  
  // Handler for main branch - production deployment
  final mainBranchHandler = WebhookHandler(
    branch: 'refs/heads/main',
    event: 'push',
    projectPath: '/var/www/production',
    runCommand: [
      'git pull origin main',
      'dart pub get',
      'dart run build_runner build --delete-conflicting-outputs',
      'systemctl restart myapp',
    ],
    timeout: Duration(minutes: 10),
    maxRetries: 3,
    secret: WebhookSecret(secret: 'prod-webhook-secret'),
  );
  
  // Handler for staging branch - staging deployment
  final stagingBranchHandler = WebhookHandler(
    branch: 'refs/heads/staging',
    event: 'push',
    projectPath: '/var/www/staging',
    runCommand: [
      'git pull origin staging',
      'dart pub get',
      'dart run build_runner build --delete-conflicting-outputs',
      'systemctl restart myapp-staging',
    ],
    timeout: Duration(minutes: 5),
    maxRetries: 2,
    secret: WebhookSecret(secret: 'staging-webhook-secret'),
  );
  
  // Create a custom handler that routes to the appropriate branch handler
  ProcessorHandler webhookRouter = (req, res, pathArgs) async {
    // Get the JSON payload
    final payload = req.body;
    
    // Extract the branch from the payload
    final ref = payload['ref'] as String?;
    
    if (ref == 'refs/heads/main') {
      return mainBranchHandler.handler(req, res, pathArgs);
    } else if (ref == 'refs/heads/staging') {
      return stagingBranchHandler.handler(req, res, pathArgs);
    }
    
    // If the branch doesn't match, return a response
    return res.status(200).json({
      'message': 'No action taken for branch: $ref',
    });
  };
  
  // Create a router with the webhook endpoint
  final router = Router()
    .post('webhook', webhookRouter);
  
  // Create and start the server
  final server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
  print('Advanced webhook server running on port 3000');
}
```

## Webhook Logging

You can enable logging for your webhook executions:

```dart
import 'dart:io';
import 'package:dart_flux/dart_flux.dart';
import 'package:dart_flux/core/webhook/utils/webhook_logger.dart';

void main() async {
  // Create a webhook logger
  final logger = WebhookLogger(
    logFilePath: 'logs/webhook.log',
    printToConsole: true,
  );
  
  // Create a webhook handler with logging
  final webhookHandler = WebhookHandler(
    branch: 'refs/heads/main',
    event: 'push',
    runCommand: [
      'git pull',
      'dart pub get',
    ],
    // Additional configuration...
  );
  
  // Set up custom logging in the handler function
  ProcessorHandler loggingHandler = (req, res, pathArgs) async {
    logger.log('Webhook received');
    
    try {
      // Execute the webhook handler
      final result = await webhookHandler.handler(req, res, pathArgs);
      logger.log('Webhook processed successfully');
      return result;
    } catch (e) {
      logger.log('Webhook error: $e');
      return res.status(500).json({
        'error': 'Internal server error',
        'message': e.toString(),
      });
    }
  };
  
  // Create a router with the logging handler
  final router = Router()
    .post('webhook', loggingHandler);
  
  // Create and start the server
  final server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
}
```

## Handling Different Webhook Providers

Different providers use different payload formats and signature methods. Here's an example for GitLab:

```dart
// GitLab webhook secret (uses X-Gitlab-Token header)
final gitlabSecret = WebhookSecret(
  secret: 'your-gitlab-secret',
  headerKey: 'X-Gitlab-Token',
  // GitLab uses a simple equality check, not a signature
  algorithm: 'equality', 
);

// GitLab webhook handler
final gitlabHandler = WebhookHandler(
  // GitLab uses 'ref' directly, not 'refs/heads/main'
  branch: 'main',
  event: 'push',
  runCommand: [
    'git pull',
    'dart pub get',
  ],
  secret: gitlabSecret,
);
```

## Custom Webhook Runner

You can create a custom webhook runner for more control:

```dart
import 'package:dart_flux/core/webhook/webhook_runner.dart';

// Create a custom webhook runner
final runner = WebhookRunner(
  commands: [
    'git pull',
    'dart pub get',
    'dart run build_runner build',
  ],
  workingDirectory: '/var/www/myapp',
  timeout: Duration(minutes: 5),
  maxRetries: 3,
  concurrent: false,
);

// Execute the runner
runner.run().then((_) {
  print('Commands executed successfully');
}).catchError((error) {
  print('Error executing commands: $error');
});
```

## Best Practices

1. **Use Secrets**: Always use secrets to validate webhook requests.

2. **Set Timeouts**: Configure reasonable timeouts to prevent hanging processes.

3. **Implement Retries**: Use retries for transient failures.

4. **Specify Working Directory**: Set the correct project path for command execution.

5. **Enable Logging**: Log webhook activities for debugging and auditing.

6. **Use HTTPS**: Secure your webhook endpoints with HTTPS.

7. **Limit Access**: Restrict access to webhook endpoints by IP if possible.

8. **Validate Payloads**: Verify that the payload contains expected data before processing.

9. **Respond Quickly**: Return a response to the webhook provider promptly, then process tasks asynchronously.

10. **Monitor Disk Space**: Ensure sufficient disk space for logging and command outputs.
