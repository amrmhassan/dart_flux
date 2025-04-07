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
    Router post = Router.path('post')
        .get('/', TestPostsProcessors.allPosts)
        .get('/:id', TestPostsProcessors.postData);

    Router router = Router.path('user')
        .router(post)
        .get('/', TestUserProcessors.allUsers)
        .get('/:id', TestUserProcessors.userData);

    server = Server(InternetAddress.anyIPv4, 0, router, loggerEnabled: false);
    await server.run();
    dio = dioPort(server.port);
  });
  tearDownAll(() async {
    await server.close();
  });
  group('1st router path test', () {
    test('all users', () async {
      var res = await dio.get('/user');
      expect(res.data, 'all users');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('single user', () async {
      var res = await dio.get('/user/userId');
      expect(res.data, 'user userId');
      expect(res.statusCode, HttpStatus.ok);
    });
  });
  group('2st router path test', () {
    test('all user posts', () async {
      var res = await dio.get('/user/post');
      expect(res.data, 'all posts');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('single user post', () async {
      var res = await dio.get('/user/post/postId');
      expect(res.data, 'post postId');
      expect(res.statusCode, HttpStatus.ok);
    });
  });
}
