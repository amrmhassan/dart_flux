import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'api_caller.dart';
import 'constants/endpoint.dart';
import 'constants/test_processors.dart';

void main() {
  late Server server;
  late Dio dio;

  setUpAll(() async {
    Router router = Router()
        .get(Endpoint.test, TestProcessors.done)
        .post(Endpoint.test, TestProcessors.done)
        .put(Endpoint.test, TestProcessors.done)
        .delete(Endpoint.test, TestProcessors.done)
        .head(Endpoint.test, TestProcessors.done)
        .connect(Endpoint.test, TestProcessors.done)
        .options(Endpoint.test, TestProcessors.done)
        .trace(Endpoint.test, TestProcessors.done)
        .patch(Endpoint.test, TestProcessors.done);
    server = Server(InternetAddress.anyIPv4, 0, router, loggerEnabled: false);
    await server.run();
    dio = dioPort(server.port);
  });
  tearDownAll(() async {
    await server.close();
  });
  group('Testing simple requests with available methods', () {
    test('Simple get request', () async {
      var res = await dio.get(Endpoint.test);
      expect(res.data, 'done get');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('Simple post request', () async {
      var res = await dio.post(Endpoint.test);
      expect(res.data, 'done post');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('Simple put request', () async {
      var res = await dio.put(Endpoint.test);
      expect(res.data, 'done put');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('Simple delete request', () async {
      var res = await dio.delete(Endpoint.test);
      expect(res.data, 'done delete');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('Simple head request', () async {
      var res = await dio.head(Endpoint.test);
      expect(res.data, '');
      expect(res.statusCode, HttpStatus.ok);
    });

    test('Simple options request', () async {
      var res = await dio.request(
        Endpoint.test,
        options: Options(method: 'OPTIONS'),
      );
      expect(res.data, 'done options');
      expect(res.statusCode, HttpStatus.ok);
    });

    test('Simple patch request', () async {
      var res = await dio.patch(Endpoint.test);
      expect(res.data, 'done patch');
      expect(res.statusCode, HttpStatus.ok);
    });
  });
}
