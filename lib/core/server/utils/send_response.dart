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
    int code,
  ) async {
    response = response.write(v, code: code);

    response = await response.close();
    return response;
  }

  static Future<FluxResponse> error(FluxResponse response, Object error) {
    if (error is ServerError) {
      return _write(response, {
        "error": error.msg,
        "description": error.description,
        "extra": error.extra,
      }, error.code);
    } else {
      return response.write(error, code: 500).close();
    }
  }

  static Future<FluxResponse> data(FluxResponse response, Object data) {
    return _write(response, data, HttpStatus.ok);
  }

  static Future<FluxResponse> notFound(FluxResponse response, [Object? data]) {
    return _write(
      response,
      data ?? 'Requested data not found',
      HttpStatus.notFound,
    );
  }

  static Future<FluxResponse> unauthorized(
    FluxResponse response, [
    Object? data,
  ]) {
    return _write(response, data ?? 'Not authorized', HttpStatus.unauthorized);
  }

  static Future<FluxResponse> badRequest(
    FluxResponse response, [
    Object? data,
  ]) {
    return _write(
      response,
      data ?? 'Sent body is not valid',
      HttpStatus.badRequest,
    );
  }

  static Future<FluxResponse> json(FluxResponse response, Object data) {
    response.headers.contentType = ContentType.json;

    return _write(response, convert.json.encode(data), HttpStatus.ok);
  }

  static Future<FluxResponse> html(FluxResponse response, Object data) {
    response.headers.contentType = ContentType.html;

    return _write(response, data, HttpStatus.ok);
  }

  static Future<FluxResponse> binary(FluxResponse response, List<int> bytes) {
    response.headers.contentType = ContentType.binary;

    return response.add(bytes, code: HttpStatus.ok).close();
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
