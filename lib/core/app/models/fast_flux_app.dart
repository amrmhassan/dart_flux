import 'dart:io';

import 'package:dart_flux/core/app/interface/app_interface.dart';
import 'package:dart_flux/core/server/execution/interface/server_interface.dart';
import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/interface/request_processor.dart';

class FastFluxApp implements AppInterface {
  @override
  late ServerInterface serverInterface;
  late dynamic ip;
  late int port;
  final RequestProcessor processor;
  final bool allowLogging;

  FastFluxApp(
    this.processor, {
    dynamic ip,
    int? port,
    this.allowLogging = true,
  }) {
    this.ip = ip ?? InternetAddress.anyIPv4;
    this.port = port ?? 0;
    serverInterface = Server(
      this.ip,
      this.port,
      processor,
      loggerEnabled: allowLogging,
    );
  }

  @override
  Future<void> run() async {
    await serverInterface.run();
  }
}
