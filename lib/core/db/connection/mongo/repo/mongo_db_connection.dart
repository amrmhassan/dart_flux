import 'package:dart_flux/core/db/base/mongo/models/coll_ref_mongo.dart';
import 'package:dart_flux/core/db/connection/interface/db_connection_interface.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/execution/interface/flux_logger_interface.dart';
import 'package:dart_flux/core/server/execution/repo/flux_logger.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDbConnection implements DbConnectionInterface {
  MongoDbConnection(this.connLink, {this.loggerEnabled = true, this.logger}) {
    if (!loggerEnabled)
      return; // Only add logging middlewares if logging is enabled.
    logger ??= FluxPrintLogger(
      loggerEnabled: loggerEnabled,
    ); // Initialize the logger if not provided.
  }
  Db? _db;

  @override
  Future<Db> connect() async {
    logger?.rawLog('connecting to db');
    _db = await Db.create(connLink);
    await _db!.open();
    logger?.rawLog('db connected');

    return _db!;
  }

  @override
  bool get connected =>
      _db != null && _db!.isConnected && _db!.masterConnection.connected;

  @override
  String connLink;

  @override
  Future fixConnection() async {
    if (connected) return;
    return connect();
  }

  @override
  Db get db {
    if (_db == null) {
      throw ServerError('db is not initialized');
    }
    if (!connected) {
      throw ServerError('db is not connected');
    }
    return _db!;
  }

  CollRefMongo collection(String name) {
    return CollRefMongo(name, db);
  }

  @override
  FluxLoggerInterface? logger;

  @override
  bool loggerEnabled;
}
