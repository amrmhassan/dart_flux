import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'api_caller.dart';
import 'constants/test_processors.dart';

void main() {
  late Server server;
  late Dio dio;

  setUpAll(() async {
    Router router = Router().get('/noAlias/*', FolderProcessors.noAlias);
    server = Server(InternetAddress.anyIPv4, 0, router, loggerEnabled: false);
    await server.run();
    dio = dioPort(server.port);
  });
  tearDownAll(() async {
    await server.close();
  });
  group('Serve Folder', () {
    // direct child
    test('serve folder direct child', () async {
      var res = await dio.get(
        '/noAlias/file1.bin',
        options: Options(responseType: ResponseType.bytes),
      );
      var length = res.data.length;
      expect(length, 20);
      expect(res.statusCode, HttpStatus.ok);
    });
    // child of a sub dir
    // without alias
    // with alias
    // serve folder content like folder children
    // block folder content
  });
}
