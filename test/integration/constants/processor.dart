import 'package:dart_flux/core/server/routing/models/processor.dart';
import 'package:dart_flux/core/server/utils/send_response.dart';

class Processors {
  static ProcessorHandler doneProcessor = (request, response, pathArgs) {
    return SendResponse.data(response, 'done ${request.method.name}');
  };
}
