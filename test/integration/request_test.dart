import 'dart:io';

import 'package:dart_flux/core/server/execution/repo/server.dart';
import 'package:dart_flux/core/server/routing/models/router.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import '../helper/file_helper.dart';
import '../helper/form_data_helper.dart';
import 'api_caller.dart';
import 'constants/test_processors.dart';

void main() {
  late Server server;
  late Dio dio;

  setUpAll(() async {
    Router router = Router()
        .post('/user', Processors.jsonBody)
        .post('/userForm', Processors.bytesFormBodyNoFiles)
        .post('/userFormWithFile', Processors.bytesFormBodyWithFiles)
        .post('/userFilesForm', Processors.bytesFormBodyNoFiles)
        .post('/userFilesFormWithFile', Processors.filesFormBodyWithFiles)
        .post('/file', Processors.receiveFile);
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
      FormDataHelper helper = FormDataHelper();
      FileHelper fileHelper = FileHelper();
      var file = await fileHelper.create();
      helper.addEntry('name', 'Amr Hassan');

      await helper.addFile(file);
      var form = helper.formDataRenderer;

      var res = await dio.post('/userForm', data: form);
      await fileHelper.delete();

      expect(res.data['code'], 'files-not-allowed-in-form');
      expect(res.statusCode, HttpStatus.badRequest);
    });
    test('form file body no files allowed', () async {
      FormDataHelper helper = FormDataHelper();
      FileHelper fileHelper = FileHelper();
      var file = await fileHelper.create();
      helper.addEntry('name', 'Amr Hassan');

      await helper.addFile(file);
      var form = helper.formDataRenderer;

      var res = await dio.post('/userFilesForm', data: form);
      await fileHelper.delete();

      expect(res.data['code'], 'files-not-allowed-in-form');
      expect(res.statusCode, HttpStatus.badRequest);
    });
    test('form bytes body with files allowed', () async {
      FormDataHelper helper = FormDataHelper();
      FileHelper fileHelper = FileHelper();
      var file = await fileHelper.create();
      int length = file.lengthSync();
      helper.addEntry('name', 'Amr Hassan');

      await helper.addFile(file, fileKey: 'file');
      var form = helper.formDataRenderer;

      var res = await dio.post('/userFormWithFile', data: form);
      await fileHelper.delete();

      expect(res.data, '$length');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('form file body with files allowed', () async {
      FormDataHelper helper = FormDataHelper();
      FileHelper fileHelper = FileHelper();
      var file = await fileHelper.create();
      int length = file.lengthSync();

      helper.addEntry('name', 'Amr Hassan');

      await helper.addFile(file, fileKey: 'file');
      var form = helper.formDataRenderer;

      var res = await dio.post('/userFilesFormWithFile', data: form);
      await fileHelper.delete();

      expect(res.data, '$length');
      expect(res.statusCode, HttpStatus.ok);
    });
    test('receive file', () async {
      FileHelper fileHelper = FileHelper();
      var file = await fileHelper.create();
      int length = file.lengthSync();

      var bytes = await file.readAsBytes();

      var res = await dio.post('/file', data: bytes);
      await fileHelper.delete();

      expect(res.data, '$length');
      expect(res.statusCode, HttpStatus.ok);
    });
  });
}
