import 'dart:io';

import 'package:dart_flux/core/webhook/webhook_handler.dart';
import 'package:dart_flux/dart_flux.dart';

void main(List<String> args) async {
  final webhookHandler = WebhookHandler();

  // Get the handler function to register with your router
  ProcessorHandler handler = webhookHandler.handler;
  Router router = Router().post('/webhook', handler);
  Server server = Server(InternetAddress.anyIPv4, 4000, router);
  await server.run();
}
