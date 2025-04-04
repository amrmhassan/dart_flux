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

  static Future<FluxResponse> error(
    FluxResponse response,
    Object err, {
    int? code,
  }) {
    if (err is ServerError) {
      return json(response, err.toJson(), code: code ?? err.code);
    } else {
      ServerError e = ServerError(err.toString(), code);
      return error(response, e);
    }
  }

  static Future<FluxResponse> data(
    FluxResponse response,
    Object data, {
    int? code,
  }) {
    return _write(response, data, code ?? HttpStatus.ok);
  }

  static Future<FluxResponse> notFound(FluxResponse response, [Object? data]) {
    return error(
      response,
      data ?? 'Requested data not found',
      code: HttpStatus.notFound,
    );
  }

  static Future<FluxResponse> unauthorized(
    FluxResponse response, [
    Object? data,
  ]) {
    return error(
      response,
      data ?? 'Not authorized',
      code: HttpStatus.unauthorized,
    );
  }

  static Future<FluxResponse> badRequest(
    FluxResponse response, [
    Object? data,
  ]) {
    return error(
      response,
      data ?? 'Sent body is not valid',
      code: HttpStatus.badRequest,
    );
  }

  static Future<FluxResponse> json(
    FluxResponse response,
    Object data, {
    int? code,
  }) {
    response.headers.contentType = ContentType.json;

    return _write(response, convert.json.encode(data), code ?? HttpStatus.ok);
  }

  static Future<FluxResponse> html(
    FluxResponse response,
    Object data, {
    int? code,
  }) {
    response.headers.contentType = ContentType.html;

    return _write(response, data, code ?? HttpStatus.ok);
  }

  static Future<FluxResponse> binary(
    FluxResponse response,
    List<int> bytes, {
    int? code,
  }) {
    response.headers.contentType = ContentType.binary;

    return response.add(bytes, code: code ?? HttpStatus.ok).close();
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
