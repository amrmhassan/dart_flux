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
  static ProcessorHandler formBodyNoFiles = (
    request,
    response,
    pathArgs,
  ) async {
    var body = await request.bytesForm(acceptFormFiles: false);
    String name = body.getField('name')!.value;

    return SendResponse.data(response, 'user name is $name');
  };
}
