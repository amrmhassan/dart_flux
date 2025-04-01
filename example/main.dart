import 'dart:io';

import 'package:dart_flux/constants/date_constants.dart';
import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/handler.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/models/middleware.dart';
import 'package:dart_flux/core/server/routing/models/router.dart';

void main(List<String> args) async {
  print(DateTime.now());
  print(DateTime.now().toUtc());
  var handler = Handler('/hello', HttpMethod.get, (
    request,
    response,
    pathArgs,
  ) async {
    await response
      ..write('Hello world')
      ..close();
    return response;
  }).middleware((request, response, pathArgs) {
    request.context.add('Time', now);
    print('Hello');
    return request;
  });
  var middleware = Middleware(null, null, (request, response, pathArgs) {
    return request;
  });
  var documentsHandler = Handler('/documents', HttpMethod.get, (
    request,
    response,
    pathArgs,
  ) async {
    await response.write('User documents').close();
    return response;
  });
  var subRouter = Router().handler(documentsHandler);
  var router = Router.path(
    '/user',
  ).handler(handler).middleware(middleware).router(subRouter);
  Server server = Server(InternetAddress.anyIPv4, 3000, router);
  await server.run();
}
