// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

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
    return _reader.readJson();
  }

  Future<String> get asString {
    return _reader.readString();
  }

  Future<List<int>> get asBytes {
    return _reader.readBytes();
  }

  /// this is a normal form reader (will save files to the storage)
  Future<FormData> form({
    String saveFolder = 'temp',
    bool acceptFormFiles = true,
  }) {
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
    return _multipartReader.receiveFile(path: path);
  }

  Future<BytesFormData> bytesForm({bool acceptFormFiles = true}) {
    return _multipartReader.readFormBytes(acceptFormFiles: acceptFormFiles);
  }
}
