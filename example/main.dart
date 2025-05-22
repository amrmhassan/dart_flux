import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';
import 'package:dart_flux/core/webhook/webhook_handler.dart';

void main(List<String> args) async {
  final webhookHandler = WebhookHandler();

  // Get the handler function to register with your router
  ProcessorHandler handler = webhookHandler.handler;
  Router router = Router().post('/webhook', handler).post('test', (
    req,
    res,
    pathArgs,
  ) async {
    return res.success('Hello World');
  });
  Server server = Server(InternetAddress.anyIPv4, 4000, router);
  await server.run();
}
