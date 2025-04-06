import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_flux/core/errors/error_string.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/parser/interface/request_reader_interface.dart';

class RequestReader implements RequestReaderInterface {
  RequestReader(this.request);
  Future<dynamic> readJson() async {
    try {
      var jsonBody = json.decode(await readString());
      return jsonBody;
    } catch (e, s) {
      throw ServerError.fromCatch(
        msg: errorString.invalidJsonBody,
        status: HttpStatus.badRequest,
        e: e,
        s: s,
        code: errorCode.invalidJsonBody,
      );
    }
  }

  Future<String> readString() async {
    try {
      final contentType = request.headers.contentType;
      var mimeType = contentType?.primaryType;
      List<String> allowedMimes = ['application', 'text'];
      // allowed mimes = text,application
      if (!allowedMimes.any((element) => element == mimeType)) {
        throw ServerError(
          errorString.invalidStringBody,
          status: HttpStatus.unsupportedMediaType,
        );
      }
      if (contentType != null && contentType.charset != null) {
        final decoder = Encoding.getByName(contentType.charset!);
        if (decoder != null) {
          var decodedBody = decoder.decode(await readBytes());
          return decodedBody;
        }
      }
      var decodedBody = await utf8.decoder.bind(request).join();
      return decodedBody;
    } catch (e, s) {
      throw ServerError.fromCatch(
        msg: errorString.invalidStringBody,
        status: HttpStatus.badRequest,
        e: e,
        s: s,
        code: errorCode.invalidStringBody,
      );
    }
  }

  Future<List<int>> readBytes() async {
    try {
      final completer = Completer<List<int>>();
      final bytes = <int>[];

      request.listen(
        (data) {
          bytes.addAll(data);
        },
        onDone: () => completer.complete(bytes),
        onError: (error) => completer.completeError(error),
        cancelOnError: true,
      );

      return completer.future;
    } catch (e, s) {
      throw ServerError.fromCatch(
        msg: errorString.invalidBytesBody,
        status: HttpStatus.badRequest,
        e: e,
        s: s,
        code: errorCode.invalidBytesBody,
      );
    }
  }

  @override
  HttpRequest request;
}
