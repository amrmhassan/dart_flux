// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'package:dart_flux/core/errors/error_string.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/routing/interface/http_entity.dart';
import 'package:dart_flux/core/server/parser/interface/multi_part_interface.dart';
import 'package:dart_flux/core/server/parser/interface/request_reader_interface.dart';
import 'package:dart_flux/core/server/parser/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/routing/models/context.dart';
import 'package:dart_flux/core/server/routing/models/flux_response.dart';
import 'package:dart_flux/core/server/parser/models/form_data.dart';
import 'package:dart_flux/core/server/routing/models/http_method.dart';
import 'package:dart_flux/core/server/parser/repo/flux_multi_part.dart';
import 'package:dart_flux/core/server/parser/repo/request_reader.dart';

/// The FluxRequest class wraps around an HttpRequest and provides additional utility methods
/// to parse and handle request data in various formats (JSON, string, bytes, form, etc.).
/// It supports multipart form data, file uploads, and checking for request size limits.
class FluxRequest extends HttpEntity {
  final HttpRequest _request;

  FluxRequest(this._request) {
    // Initialize the reader and multipart reader for parsing the request body
    _reader = RequestReader(request);
    _multipartReader = FluxMultiPart(request);
    _context = Context();
  }

  // Context object to store request-related data during processing
  late Context _context;

  // Returns the context associated with this request
  Context get context => _context;

  // Reader for handling JSON, string, and byte data from the request body
  late RequestReaderInterface _reader;

  // Multipart reader for handling form data and file uploads
  late MultiPartInterface _multipartReader;

  // Access to the headers of the HTTP request
  HttpHeaders get headers => _request.headers;

  // A map version of the request headers, where each header key is mapped to its comma-separated values
  Map<String, String> get headersMap {
    Map<String, String> map = {};
    headers.forEach((key, value) {
      map[key] = value.join(',');
    });
    return map;
  }

  // The URI of the request
  Uri get uri => _request.uri;

  // The URI requested by the client (including any redirects)
  Uri get requestedUri => _request.requestedUri;

  // The path part of the request URI
  String get path => _request.uri.path;

  // The query parameters parsed from the URI
  Map<String, String> get queryParameters => _request.uri.queryParameters;

  // Override hashCode to use the hash of the underlying HttpRequest
  @override
  int get hashCode => _request.hashCode;

  // Equality operator based on the hashCode of the HttpRequest
  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }

  // Returns a FluxResponse object for sending responses
  FluxResponse get response => FluxResponse(_request);

  // Returns the HTTP method of the request as an HttpMethod object
  HttpMethod get method => methodFromString(_request.method);

  // The underlying HttpRequest object
  HttpRequest get request => _request;

  /// Parses the request body as JSON.
  ///
  /// This method reads the body as a string, decodes it into a JSON object,
  /// and throws an error if the body is not valid JSON.
  Future<dynamic> get asJson {
    _checkMaxSize();
    return _reader.readJson();
  }

  /// Parses the request body as a string.
  ///
  /// Reads the entire body as a string, checking for size limits before processing.
  Future<String> get asString {
    _checkMaxSize();
    return _reader.readString();
  }

  /// Parses the request body as raw bytes.
  ///
  /// Reads the entire body as bytes, ensuring the size limit is not exceeded.
  Future<List<int>> get asBytes {
    _checkMaxSize();
    return _reader.readBytes();
  }

  /// Parses the request body as a form, supporting file uploads and field data.
  ///
  /// If [acceptFormFiles] is true, the form will accept file uploads, and [saveFolder]
  /// defines where the uploaded files will be saved. Defaults to 'temp' folder.
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

  /// Receives and saves a file from the request body.
  ///
  /// The [path] defines where to store the file, and the method allows for
  /// specifying behavior when the file already exists (throw or override).
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

  /// Parses the request body as form data in bytes, supporting file uploads.
  Future<BytesFormData> bytesForm({bool acceptFormFiles = true}) {
    _checkMaxSize();
    return _multipartReader.readFormBytes(acceptFormFiles: acceptFormFiles);
  }

  // Maximum request size, set by the user to enforce size limits
  int? _maxSize;

  /// Sets the maximum allowed size for the request body in bytes.
  ///
  /// If the request body exceeds this size, an error will be thrown.
  FluxRequest setMaxSize(int bytes) {
    _maxSize = bytes;
    _checkMaxSize();
    return this;
  }

  /// Checks if the request size exceeds the defined maximum size.
  ///
  /// Throws a [ServerError] if the content length exceeds the maximum size.
  void _checkMaxSize() {
    if (_maxSize != null) {
      int length = _request.contentLength;
      if (length == -1) {
        // If the content length is unknown, throw an error
        throw ServerError(
          errorString.unknownRequestSize,
          code: errorCode.unknownRequestSize,
          status: HttpStatus.badRequest,
        );
      }
      if (length > _maxSize!) {
        // If the request exceeds the max size, throw an error
        throw ServerError(
          '${errorString.largeRequestSize}: $length > $_maxSize',
          code: errorCode.largeRequestSize,
          status: HttpStatus.badRequest,
        );
      }
    }
  }
}
