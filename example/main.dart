import 'package:dart_flux/core/db/connection/mongo/repo/mongo_db_connection.dart';

void main(List<String> args) async {
  var conn = await MongoDbConnection('mongodb://localhost:27017/flux');
  await conn.connect();
  var collection = conn.collection('Hello');
  var doc = collection.doc('user1');
  var data = await doc.getData();
  print(data);
  // Router router = Router().get('/*', (request, response, pathArgs) async {
  //   return SendResponse.serveFolder(
  //     response: response,
  //     server: FolderServer(path: './storage'),
  //     requestedPath: pathArgs['*'],
  //     blockIfFolder: false,
  //     serveFolderContent: true,
  //   );
  // });
  // Server server = Server(InternetAddress.anyIPv4, 3000, router);
  // await server.run();
}

//  dart run build_runner build --delete-conflicting-outputs
//  dart run build_runner watch --delete-conflicting-outputs
