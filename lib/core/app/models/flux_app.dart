import 'package:dart_flux/core/app/interface/app_interface.dart';
import 'package:dart_flux/core/server/execution/interface/server_interface.dart';

class FluxApp implements AppInterface {
  @override
  ServerInterface serverInterface;

  FluxApp({required this.serverInterface});

  ServerInterface get server {
    return serverInterface;
  }

  @override
  Future<void> run() async {
    await serverInterface.run();
  }
}
