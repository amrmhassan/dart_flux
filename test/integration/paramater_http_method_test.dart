import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/router.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'api_caller.dart';
import 'constants/test_processors.dart';

void main() {
  late Server server;
  late Dio dio;

  setUpAll(() async {
    Router router = Router()
        .get('/user/welcome/:id', Processors.welcomeID)
        .get('/user/:userName', Processors.userName)
        .get('/:path', Processors.path)
        .get('/*', Processors.wildcard);
    server = Server(InternetAddress.anyIPv4, 0, router, loggerEnabled: false);
    await server.run();
    dio = dioPort(server.port);
  });
  tearDownAll(() async {
    await server.close();
  });
  group('Testing path with parameters', () {
    test('3rd parameter', () async {
      var res = await dio.get('/user/welcome/1234');
      expect(res.data, 'welcome, 1234');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('2rd parameter', () async {
      var res = await dio.get('/user/AmrHassan');
      expect(res.data, 'hello, AmrHassan');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('in a path', () async {
      var res = await dio.get('/some_path_will_be_here');
      expect(res.data, 'provided path is some_path_will_be_here');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('wild card', () async {
      var res = await dio.get('/more/path/to/follow');
      expect(res.data, 'provided path is more/path/to/follow');
      expect(res.statusCode, HttpStatus.ok);
    });
  });
}
