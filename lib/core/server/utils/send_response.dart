import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';

class SendResponse {
  static Future<FluxResponse> error(FluxResponse response, Object error) {
    if (error is ServerError) {
      return response.write(error.msg, code: error.code).close();
    } else {
      return response.write(error, code: 500).close();
    }
  }
}
