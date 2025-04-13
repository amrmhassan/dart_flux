import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';

abstract class DbConnectionInterface {
  late String connLink;
  Future<dynamic> connect();
  bool get connected;
  Future<dynamic> fixConnection();
  dynamic get db;

  late final bool loggerEnabled;

  late FluxLoggerInterface? logger;
}
