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
    Router router = Router()
        .get('/noAlias/*', FolderProcessors.noAlias)
        .get('/subDirNoAlias/*', FolderProcessors.subDirNoAlias)
        .get('/subDirWithAlias/*', FolderProcessors.subDirWithAlias)
        .get('/folderContent/*', FolderProcessors.folderContent)
        .get('/alias/*', FolderProcessors.alias);
    server = Server(InternetAddress.anyIPv4, 0, router, loggerEnabled: false);
    await server.run();
    dio = dioPort(server.port);
  });
  tearDownAll(() async {
    await server.close();
  });
  group('Serve Folder', () {
    // direct child
    test('serve folder direct child no alias', () async {
      var res = await dio.get(
        '/noAlias/file1.bin',
        options: Options(responseType: ResponseType.bytes),
      );
      var length = res.data.length;
      expect(length, 20);
      expect(res.statusCode, HttpStatus.ok);
    });
    test('serve folder direct child with alias', () async {
      var res = await dio.get(
        '/alias/bucket/file1.bin',
        options: Options(responseType: ResponseType.bytes),
      );
      var length = res.data.length;
      expect(length, 20);
      expect(res.statusCode, HttpStatus.ok);
    });
    test('serve file in a sub dir without alias', () async {
      var res = await dio.get(
        '/subDirNoAlias/subDir/file1.bin',
        options: Options(responseType: ResponseType.bytes),
      );
      var length = res.data.length;
      expect(length, 20);
      expect(res.statusCode, HttpStatus.ok);
    });
    test('serve file in a sub dir with alias', () async {
      var res = await dio.get(
        '/subDirWithAlias/bucket/subDir/file1.bin',
        options: Options(responseType: ResponseType.bytes),
      );
      var length = res.data.length;
      expect(length, 20);
      expect(res.statusCode, HttpStatus.ok);
    });
    test('serve folder content', () async {
      var res = await dio.get(
        '/folderContent/bucket',
        // options: Options(responseType: ResponseType.bytes),
      );
      var path = (res.data as List).first['path'];
      expect(path, 'bucket/subDir');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('serve sub folder content ', () async {
      var res = await dio.get(
        '/folderContent/bucket/subDir',
        // options: Options(responseType: ResponseType.bytes),
      );
      var path = (res.data as List).first['path'];
      expect(path, 'bucket/subDir/file1.bin');
      expect(res.statusCode, HttpStatus.ok);
    });
    // child of a sub dir
    // without alias
    // with alias
    // serve folder content like folder children
    // block folder content
  });
}
