// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'package:dart_flux/core/errors/error_string.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/routing/interface/multi_part_interface.dart';
import 'package:dart_flux/core/server/routing/interface/request_reader_interface.dart';
import 'package:dart_flux/core/server/routing/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/routing/models/context.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/routing/models/form_data.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/routing/repo/flux_multi_part.dart';
import 'package:dart_flux/core/server/routing/repo/request_reader.dart';

class FluxRequest extends HttpEntity {
  final HttpRequest _request;

  FluxRequest(this._request) {
    _reader = RequestReader(request);
    _multipartReader = FluxMultiPart(request);
    _context = Context();
  }

  late Context _context;
  Context get context => _context;
  late RequestReaderInterface _reader;
  late MultiPartInterface _multipartReader;

  HttpHeaders get headers => _request.headers;
  Map<String, String> get headersMap {
    Map<String, String> map = {};
    headers.forEach((key, value) {
      map[key] = value.join(',');
    });
    return map;
  }

  Uri get uri => _request.uri;
  Uri get requestedUri => _request.requestedUri;
  String get path => _request.uri.path;
  Map<String, String> get queryParameters => _request.uri.queryParameters;

  @override
  int get hashCode => _request.hashCode;

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }

  FluxResponse get response => FluxResponse(_request);
  HttpMethod get method => methodFromString(_request.method);
  HttpRequest get request => _request;

  Future<dynamic> get asJson {
    _checkMaxSize();
    return _reader.readJson();
  }

  Future<String> get asString {
    _checkMaxSize();

    return _reader.readString();
  }

  Future<List<int>> get asBytes {
    _checkMaxSize();

    return _reader.readBytes();
  }

  /// this is a normal form reader (will save files to the storage)
  Future<FormData> form({
    String saveFolder = 'temp',
    bool acceptFormFiles = true,
  }) {
    _checkMaxSize();

    return _multipartReader.readForm(
      saveFolder: saveFolder,
      acceptFormFiles: acceptFormFiles,
    );
  }

  Future<File> file({
    required String path,
    bool throwErrorIfExist = true,
    bool overrideIfExist = false,
  }) {
    _checkMaxSize();

    return _multipartReader.receiveFile(
      path: path,
      throwErrorIfExist: throwErrorIfExist,
      overrideIfExist: overrideIfExist,
    );
  }

  Future<BytesFormData> bytesForm({bool acceptFormFiles = true}) {
    _checkMaxSize();

    return _multipartReader.readFormBytes(acceptFormFiles: acceptFormFiles);
  }

  int? _maxSize;
  FluxRequest setMaxSize(int bytes) {
    _maxSize = bytes;
    _checkMaxSize();
    return this;
  }

  void _checkMaxSize() {
    if (_maxSize != null) {
      int length = _request.contentLength;
      if (length == -1) {
        throw ServerError(
          errorString.unknownRequestSize,
          code: errorCode.unknownRequestSize,
          status: HttpStatus.badRequest,
        );
      }
      if (length > _maxSize!) {
        throw ServerError(
          '${errorString.largeRequestSize}: $length > $_maxSize',
          code: errorCode.largeRequestSize,
          status: HttpStatus.badRequest,
        );
      }
    }
  }
}
