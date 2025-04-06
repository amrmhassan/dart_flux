import 'package:dart_flux/core/server/execution/interface/server_interface.dart';

abstract class AppInterface {
  late ServerInterface serverInterface;
  Future<void> run();
}
