import 'dart:io';

import 'package:dart_flux/core/server/parser/models/folder_server.dart';
import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

import '../../helper/file_helper.dart';

class TestProcessors {
  static ProcessorHandler done = (request, response, pathArgs) {
    return SendResponse.data(response, 'done ${request.method.name}');
  };
  static ProcessorHandler userName = (request, response, pathArgs) {
    String userName = pathArgs['userName'];
    return SendResponse.data(response, 'hello, $userName');
  };
  static ProcessorHandler welcomeID = (request, response, pathArgs) {
    String id = pathArgs['id'];
    return SendResponse.data(response, 'welcome, $id');
  };
  static ProcessorHandler path = (request, response, pathArgs) {
    String path = pathArgs['path'];
    return SendResponse.data(response, 'provided path is $path');
  };
  static ProcessorHandler wildcard = (request, response, pathArgs) {
    String path = pathArgs['*'];
    return SendResponse.data(response, 'provided path is $path');
  };
  static ProcessorHandler jsonBody = (request, response, pathArgs) async {
    var body = await request.asJson;
    String name = body['name'];

    return SendResponse.data(response, 'user name is $name');
  };
  static ProcessorHandler bytesFormBodyNoFiles = (
    request,
    response,
    pathArgs,
  ) async {
    var body = await request.bytesForm(acceptFormFiles: false);
    String name = body.getField('name')[0].value;

    return SendResponse.data(response, 'user name is $name');
  };
  static ProcessorHandler bytesFormBodyWithFiles = (
    request,
    response,
    pathArgs,
  ) async {
    var body = await request.bytesForm();
    var file = body.getFile('file')[0];

    return SendResponse.data(response, file.bytes.length);
  };
  static ProcessorHandler filesFormBodyNoFiles = (
    request,
    response,
    pathArgs,
  ) async {
    var body = await request.form(acceptFormFiles: false);
    String name = body.getField('name')[0].value;

    return SendResponse.data(response, 'user name is $name');
  };
  static ProcessorHandler filesFormBodyWithFiles = (
    request,
    response,
    pathArgs,
  ) async {
    var body = await request.form();
    File file = body.getFile('file')[0];
    int length = file.lengthSync();
    try {
      file.parent.deleteSync(recursive: true);
    } catch (e) {
      print('Error deleting file: $e');
    }

    return SendResponse.data(response, length);
  };
  static ProcessorHandler receiveFile = (request, response, pathArgs) async {
    var noDuplicate = request.headersMap['no-duplicate'] == 'true';
    var deleteAfter =
        request.headersMap['delete-after'] == null
            ? true
            : request.headersMap['delete-after'] == 'true';
    String? pathHeaders = request.headersMap['path'];
    bool override = request.headersMap['override'] == 'true';
    String path = pathHeaders ?? './temp/file.bin';
    var file = await request.file(
      path: path,
      throwErrorIfExist: noDuplicate,
      overrideIfExist: override,
    );
    int length = file.lengthSync();
    if (deleteAfter) {
      try {
        file.parent.deleteSync(recursive: true);
      } catch (e) {
        print('Error deleting file: $e');
      }
    }

    return SendResponse.data(response, length);
  };
  static ProcessorHandler badRequest = (request, response, pathArgs) async {
    return SendResponse.badRequest(response, 'bad request');
  };
  static ProcessorHandler binary = (request, response, pathArgs) async {
    FileHelper helper = FileHelper(fileSize: 1024, filePath: 'alksjdfkla');
    var file = await helper.create();
    var bytes = file.readAsBytesSync();
    await file.delete();
    return SendResponse.binary(response, bytes);
  };
  static ProcessorHandler data = (request, response, pathArgs) async {
    return SendResponse.data(response, 'this is data');
  };
  static ProcessorHandler error = (request, response, pathArgs) async {
    return SendResponse.error(response, 'this is error');
  };
  static ProcessorHandler file = (request, response, pathArgs) async {
    FileHelper helper = FileHelper(fileSize: 1024, filePath: 'oiquweriow');
    var file = await helper.create();
    var res = await SendResponse.file(response, file);
    await file.delete();
    return res;
  };
  static ProcessorHandler html = (request, response, pathArgs) async {
    return SendResponse.html(response, 'html');
  };
  static ProcessorHandler jsonProcessor = (request, response, pathArgs) async {
    return SendResponse.json(response, {'type': "json"});
  };
  static ProcessorHandler notfound = (request, response, pathArgs) async {
    return SendResponse.notFound(response, 'data not found');
  };
  static ProcessorHandler unauthorized = (request, response, pathArgs) async {
    return SendResponse.unauthorized(response, 'unauthorized');
  };
  static ProcessorHandler stream = (request, response, pathArgs) async {
    FileHelper helper = FileHelper(filePath: 'aaaaaa');
    var file = await helper.create();
    var res = await SendResponse.stream(response, file);
    await file.delete();
    return res;
  };
  static ProcessorHandler upperMiddleware = (
    request,
    response,
    pathArgs,
  ) async {
    response.headers.add('upper', 'true');
    return SendResponse.data(response, 'upperMiddleware');
  };
  static LowerProcessor lowerMiddleware = (request, response, pathArgs) async {
    String filePath = request.context.get('filePath');
    File file = File(filePath);
    if (!file.existsSync()) {
      print('file doesn\'t exist');
      return;
    }
    file.deleteSync();
  };
  static LowerProcessor lower = (request, response, pathArgs) async {
    String filePath = request.context.get('filePath2');
    File file = File(filePath);
    if (!file.existsSync()) {
      print('file2 doesn\'t exist');
      return;
    }
    file.deleteSync();
  };

  static ProcessorHandler upper = (request, response, pathArgs) async {
    response.headers.add('upper', 'true');
    return SendResponse.data(response, 'upper');
  };
  static ProcessorHandler lowerMiddlewareHandler = (
    request,
    response,
    pathArgs,
  ) async {
    FileHelper helper = FileHelper(filePath: 'lowerMiddleware.bin');
    FileHelper helper2 = FileHelper(filePath: 'lower.bin');
    var file = await helper.create();
    var file2 = await helper2.create();
    request.context.add('filePath', file.path);
    request.context.add('filePath2', file2.path);

    return SendResponse.json(response, {
      'file1': file.path,
      'file2': file2.path,
    });
  };
}

class TestUserProcessors {
  static ProcessorHandler allUsers = (request, response, pathArgs) async {
    return SendResponse.data(response, 'all users');
  };
  static ProcessorHandler userData = (request, response, pathArgs) async {
    return SendResponse.data(response, 'user ${pathArgs['id']}');
  };
}

class TestPostsProcessors {
  static ProcessorHandler allPosts = (request, response, pathArgs) async {
    return SendResponse.data(response, 'all posts');
  };
  static ProcessorHandler postData = (request, response, pathArgs) async {
    return SendResponse.data(response, 'post ${pathArgs['id']}');
  };
}

class FolderProcessors {
  static Future<void> _deleteTempFolder() async {
    await Directory('./tempFolder').delete(recursive: true);
  }

  static ProcessorHandler noAlias = (request, response, pathArgs) async {
    FileHelper helper = FileHelper(
      fileSize: 20,
      filePath: './tempFolder/file1.bin',
    );
    await helper.create();
    var res = await SendResponse.serveFolder(
      response: response,
      server: FolderServer(path: './tempFolder'),
      requestedPath: pathArgs['*'],
    );
    await _deleteTempFolder();
    return res;
  };
  static ProcessorHandler alias = (request, response, pathArgs) async {
    FileHelper helper = FileHelper(
      fileSize: 20,
      filePath: './tempFolder/file1.bin',
    );
    await helper.create();
    String path = pathArgs['*'];
    var res = await SendResponse.serveFolder(
      response: response,
      server: FolderServer(path: './tempFolder', alias: 'bucket'),
      requestedPath: path,
    );
    await _deleteTempFolder();

    return res;
  };
  static ProcessorHandler subDirNoAlias = (request, response, pathArgs) async {
    FileHelper helper = FileHelper(
      fileSize: 20,
      filePath: './tempFolder/subDir/file1.bin',
    );
    await helper.create();
    String path = pathArgs['*'];
    var res = await SendResponse.serveFolder(
      response: response,
      server: FolderServer(path: './tempFolder'),
      requestedPath: path,
    );
    await _deleteTempFolder();
    return res;
  };
  static ProcessorHandler subDirWithAlias = (
    request,
    response,
    pathArgs,
  ) async {
    FileHelper helper = FileHelper(
      fileSize: 20,
      filePath: './tempFolder/subDir/file1.bin',
    );
    await helper.create();
    String path = pathArgs['*'];
    var res = await SendResponse.serveFolder(
      response: response,
      server: FolderServer(path: './tempFolder', alias: 'bucket'),
      requestedPath: path,
    );
    await _deleteTempFolder();
    return res;
  };
  static ProcessorHandler folderContent = (request, response, pathArgs) async {
    FileHelper helper = FileHelper(
      fileSize: 20,
      filePath: './tempFolder/subDir/file1.bin',
    );
    await helper.create();
    String path = pathArgs['*'];
    var res = await SendResponse.serveFolder(
      response: response,
      server: FolderServer(path: './tempFolder', alias: 'bucket'),
      requestedPath: path,
      serveFolderContent: true,
      blockIfFolder: false,
    );
    await _deleteTempFolder();
    return res;
  };
}
