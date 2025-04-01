import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_flux/core/server/routing/interface/request_reader_interface.dart';

class RequestReader implements RequestReaderInterface {
  RequestReader(this.request);
  Future<dynamic> readJson() async {
    var jsonBody = json.decode(await readString());
    return jsonBody;
  }

  Future<String> readString() async {
    final contentType = request.headers.contentType;
    var mimeType = contentType?.primaryType;
    List<String> allowedMimes = ['application', 'text'];
    // allowed mimes = text,application
    if (!allowedMimes.any((element) => element == mimeType)) {
      throw Exception('body content is not valid as string');
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
  }

  Future<List<int>> readBytes() async {
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
  }

  @override
  HttpRequest request;
}
