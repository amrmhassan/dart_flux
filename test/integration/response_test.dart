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
        .post('/badRequest', TestProcessors.badRequest)
        .post('/binary', TestProcessors.binary)
        .post('/data', TestProcessors.data)
        .post('/error', TestProcessors.error)
        .post('/file', TestProcessors.file)
        .post('/html', TestProcessors.html)
        .post('/json', TestProcessors.jsonProcessor)
        .post('/notfound', TestProcessors.notfound)
        .post('/unauthorized', TestProcessors.unauthorized)
        .post('/stream', TestProcessors.stream);
    server = Server(InternetAddress.anyIPv4, 0, router, loggerEnabled: false);
    await server.run();
    dio = dioPort(server.port);
  });
  tearDownAll(() async {
    await server.close();
  });
  group('Testing send response', () {
    test('bad request', () async {
      var res = await dio.post('/badRequest');
      expect(res.data['msg'], 'bad request');
      expect(res.statusCode, HttpStatus.badRequest);
    });

    test('binary', () async {
      var res = await dio.post(
        '/binary',
        options: Options(responseType: ResponseType.bytes),
      );
      expect(res.data.length, 1024);
      expect(res.statusCode, HttpStatus.ok);
    });
    test('data', () async {
      var res = await dio.post('/data');

      expect(res.data, 'this is data');
      expect(res.statusCode, HttpStatus.ok);
    });

    test('error', () async {
      var res = await dio.post('/error');
      expect(res.data['msg'], 'this is error');
      expect(res.statusCode, HttpStatus.internalServerError);
    });
    test('file', () async {
      var res = await dio.post(
        '/file',
        options: Options(responseType: ResponseType.bytes),
      );
      var length = res.data.length;
      expect(length, 1024);
      expect(res.statusCode, HttpStatus.ok);
    });
    test('html', () async {
      var res = await dio.post('/html');
      expect(res.data, 'html');
      expect(res.statusCode, HttpStatus.ok);
      expect(
        res.headers.value('content-type'),
        equals(ContentType.html.toString()),
      );
    });
    test('json', () async {
      var res = await dio.post('/json');
      expect(res.data['type'], 'json');
      expect(res.statusCode, HttpStatus.ok);
      expect(
        res.headers.value('content-type'),
        startsWith(ContentType.json.mimeType),
      );
    });
    test('notfound', () async {
      var res = await dio.post('/notfound');
      expect(res.data['msg'], 'data not found');
      expect(res.statusCode, HttpStatus.notFound);
    });
    test('unauthorized', () async {
      var res = await dio.post('/unauthorized');
      expect(res.data['msg'], 'unauthorized');
      expect(res.statusCode, HttpStatus.unauthorized);
    });
    test('stream', () async {
      var res = await dio.post(
        '/stream',
        options: Options(responseType: ResponseType.bytes),
      );
      var length = res.data.length;
      expect(length, 1024);
      expect(res.statusCode, HttpStatus.ok);
    });
    // direct child
  });
}
