import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/lower_middleware.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/repo/router.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'api_caller.dart';
import 'constants/test_processors.dart';

void main() {
  late Server server;
  late Dio dio;

  setUpAll(() async {
    Middleware upperMiddleware = Middleware(
      '/upperMiddleware',
      HttpMethod.get,
      Processors.upperMiddleware,
    );
    LowerMiddleware lowerMiddleware = LowerMiddleware(
      '/lowerMiddleware',
      HttpMethod.get,
      Processors.lowerMiddleware,
    );

    Router router = Router()
        .upperMiddleware(upperMiddleware)
        .upper(Processors.upper)
        .get('/upper', Processors.unauthorized)
        .get('/upperMiddleware', Processors.unauthorized);

    Router parent = Router()
        .lowerMiddleware(lowerMiddleware)
        .router(router)
        .get('/lowerMiddleware', Processors.unauthorized);
    server = Server(InternetAddress.anyIPv4, 0, parent, loggerEnabled: false);
    await server.run();
    dio = dioPort(server.port);
  });
  tearDownAll(() async {
    await server.close();
  });
  group('Upper middlewares', () {
    test('upperMiddleware method', () async {
      var res = await dio.get('/upperMiddleware');
      expect(res.data, 'upperMiddleware');
      expect(res.statusCode, HttpStatus.ok);
      expect(res.headers['upper']!.first, 'true');
    });
    test('upper method', () async {
      var res = await dio.get('/upper');
      expect(res.data, 'upper');
      expect(res.statusCode, HttpStatus.ok);
      expect(res.headers['upper']!.first, 'true');
    });
    test('middleware not found', () async {
      var res = await dio.get('/upperNotFound');
      expect(res.data['msg'], 'request path not found');
      expect(res.statusCode, HttpStatus.notFound);
    });
    test('lowerMiddleware method', () async {
      var res = await dio.get('/lowerMiddleware');
      expect(res.data['msg'], 'unauthorized');
      expect(res.statusCode, HttpStatus.unauthorized);
    });
  });
}
