import 'dart:io';

import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

class Processors {
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
    String name = body.getField('name')!.value;

    return SendResponse.data(response, 'user name is $name');
  };
  static ProcessorHandler bytesFormBodyWithFiles = (
    request,
    response,
    pathArgs,
  ) async {
    var body = await request.bytesForm();
    var file = body.getFile('file')!;

    return SendResponse.data(response, file.bytes.length);
  };
  static ProcessorHandler filesFormBodyNoFiles = (
    request,
    response,
    pathArgs,
  ) async {
    var body = await request.form(acceptFormFiles: false);
    String name = body.getField('name')!.value;

    return SendResponse.data(response, 'user name is $name');
  };
  static ProcessorHandler filesFormBodyWithFiles = (
    request,
    response,
    pathArgs,
  ) async {
    var body = await request.form();
    File file = body.getFile('file')!;
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
}
