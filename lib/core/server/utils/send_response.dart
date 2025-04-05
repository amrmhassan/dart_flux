import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/routing/models/flux_request.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/utils/response_utils.dart';
import 'dart:convert' as convert;

final ResponseUtils _responseUtils = ResponseUtils();

class SendResponse {
  static Future<FluxResponse> _write(
    FluxResponse response,
    Object v,
    int status,
  ) async {
    response = response.write(v, code: status);

    response = await response.close();
    return response;
  }

  static Future<FluxResponse> error(
    FluxResponse response,
    Object err, {
    int? status,
  }) {
    if (err is ServerError) {
      return json(response, err.toJson(), status: status ?? err.status);
    } else {
      ServerError e = ServerError(err.toString(), status: status);
      return error(response, e);
    }
  }

  static Future<FluxResponse> data(
    FluxResponse response,
    Object data, {
    int? status,
  }) {
    return _write(response, data, status ?? HttpStatus.ok);
  }

  static Future<FluxResponse> notFound(FluxResponse response, [Object? data]) {
    return error(
      response,
      data ?? 'Requested data not found',
      status: HttpStatus.notFound,
    );
  }

  static Future<FluxResponse> unauthorized(
    FluxResponse response, [
    Object? data,
  ]) {
    return error(
      response,
      data ?? 'Not authorized',
      status: HttpStatus.unauthorized,
    );
  }

  static Future<FluxResponse> badRequest(
    FluxResponse response, [
    Object? data,
  ]) {
    return error(
      response,
      data ?? 'Sent body is not valid',
      status: HttpStatus.badRequest,
    );
  }

  static Future<FluxResponse> json(
    FluxResponse response,
    Object data, {
    int? status,
  }) {
    response.headers.contentType = ContentType.json;

    return _write(response, convert.json.encode(data), status ?? HttpStatus.ok);
  }

  static Future<FluxResponse> html(
    FluxResponse response,
    Object data, {
    int? status,
  }) {
    response.headers.contentType = ContentType.html;

    return _write(response, data, status ?? HttpStatus.ok);
  }

  static Future<FluxResponse> binary(
    FluxResponse response,
    List<int> bytes, {
    int? status,
  }) {
    response.headers.contentType = ContentType.binary;

    return response.add(bytes, code: status ?? HttpStatus.ok).close();
  }

  static FluxResponse file(FluxRequest request, File file) {
    _responseUtils.sendChunkedFile(request, file);
    return request.response;
  }

  static Future<FluxResponse> stream(FluxRequest request, File file) async {
    await _responseUtils.streamV2(request.request, file);
    return request.response;
  }
}
