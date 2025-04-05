import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/router.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'api_caller.dart';
import 'constants/processor.dart';

void main() {
  late Server server;
  late Dio dio;

  setUpAll(() async {
    Router router = Router()
        .post('/user', Processors.jsonBody)
        .post('/userForm', Processors.formBodyNoFiles);
    server = Server(InternetAddress.anyIPv4, 0, router, loggerEnabled: false);
    await server.run();
    dio = dioPort(server.port);
  });
  tearDownAll(() async {
    await server.close();
  });
  group('Testing request body', () {
    test('json body', () async {
      var res = await dio.post('/user', data: {'name': 'Amr Hassan'});
      expect(res.data, 'user name is Amr Hassan');
      expect(res.statusCode, HttpStatus.ok);
    });

    test('form bytes body', () async {
      var res = await dio.post(
        '/userForm',
        data: FormData.fromMap({'name': 'Amr Hassan'}),
      );
      expect(res.data, 'user name is Amr Hassan');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('form bytes body no files allowed', () async {
      var res = await dio.post(
        '/userForm',
        data: FormData.fromMap({'name': 'Amr Hassan', 'file': "./"}),
      );
      expect(res.data, 'user name is Amr Hassan');
      expect(res.statusCode, HttpStatus.badRequest);
    });
  });
}
