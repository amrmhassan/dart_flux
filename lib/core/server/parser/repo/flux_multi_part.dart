import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/errors/error_string.dart';
import 'package:dart_flux/core/errors/types/file_exists_error.dart';
import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/core/server/parser/interface/multi_part_interface.dart';
import 'package:dart_flux/core/server/parser/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/parser/models/bytes_form_field.dart';
import 'package:dart_flux/core/server/parser/models/bytes_form_file_meta.dart';
import 'package:dart_flux/core/server/parser/models/file_form_field.dart';
import 'package:dart_flux/core/server/parser/models/form_data.dart';
import 'package:dart_flux/core/server/parser/models/text_form_field.dart';
import 'package:dart_flux/extensions/string_extensions.dart';
import 'package:mime/mime.dart';

/// Class responsible for handling multipart form data in HTTP requests.
/// It implements [MultiPartInterface] and provides functionality to
/// read and parse form data, including text and files from incoming
/// HTTP requests.
class FluxMultiPart implements MultiPartInterface {
  @override
  HttpRequest request;

  /// Constructor for creating an instance of [FluxMultiPart].
  /// [request]: The HTTP request to handle multipart data.
  FluxMultiPart(this.request);

  /// Reads and parses the form data from the HTTP request.
  ///
  /// It processes both text and file data from the multipart request.
  /// - [saveFolder]: The folder where uploaded files will be saved.
  /// - [acceptFormFiles]: A flag to specify if files should be accepted in the form.
  /// Returns [FormData] containing the parsed text fields and files.
  @override
  Future<FormData> readForm({
    required String saveFolder,
    bool acceptFormFiles = true,
  }) async {
    try {
      final contentType = request.headers.contentType;
      List<TextFormField> fields = [];
      List<FileFormField> files = [];
      var transformer = MimeMultipartTransformer(
        contentType!.parameters['boundary']!,
      );
      final parts = await transformer.bind(request).toList();

      for (var part in parts) {
        var broadCast = part.asBroadcastStream();
        final disposition = part.headers[HttpHeaders.contentDisposition];
        String? name = _getDispositionKey(disposition);
        var contentType = part.headers[HttpHeaders.contentTypeHeader] ?? 'text';

        if (contentType.startsWith('text')) {
          // If the content is text, process it as a text field.
          var res = await utf8.decoder.bind(part).join();
          TextFormField result = TextFormField(name, res);
          fields.add(result);
        } else {
          // If the content is a file, process it as a file field.
          String? fileName = _extractFileName(disposition);
          if (!acceptFormFiles) {
            throw ServerError(
              errorString.filesNotAllowedInForm,
              status: HttpStatus.badRequest,
              trace: StackTrace.current,
              code: errorCode.filesNotAllowedInForm,
            );
          }
          // Save the file to the specified folder.
          var filePath = await _savePartToFile(
            broadCast,
            contentType,
            saveFolder,
            fileName,
          );
          FileFormField result = FileFormField(name, filePath);
          files.add(result);
        }
      }
      return FormData(fields: fields, files: files);
    } catch (e, s) {
      throw ServerError.fromCatch(
        msg: errorString.invalidFormBody,
        status: HttpStatus.badRequest,
        e: e,
        s: s,
        code: errorCode.invalidFormBody,
      );
    }
  }

  /// Extracts the key (name) from the content disposition header.
  ///
  /// [disposition]: The content disposition header to extract the key from.
  /// Returns the extracted key or null if not found.
  String? _getDispositionKey(String? disposition) {
    if (disposition != null) {
      final fileNameMatch = RegExp(
        'name[^;=\n]*=((["\']).*?\\2|[^;\n]*)',
      ).firstMatch(disposition);
      if (fileNameMatch != null) {
        return fileNameMatch.group(1)?.replaceAll('"', '');
      }
    }
    return null;
  }

  /// Extracts the file name from the content disposition header.
  ///
  /// [disposition]: The content disposition header to extract the file name from.
  /// Returns the extracted file name or null if not found.
  String? _extractFileName(String? disposition) {
    if (disposition == null) return null;
    final regex = RegExp(r'filename="([^"]+)"');
    final match = regex.firstMatch(disposition);

    return match?.group(1);
  }

  /// Reads and parses form data as byte streams from the HTTP request.
  ///
  /// - [acceptFormFiles]: A flag to specify if files should be accepted in the form.
  /// Returns [BytesFormData] containing the parsed text fields and files as byte arrays.
  @override
  Future<BytesFormData> readFormBytes({bool acceptFormFiles = true}) async {
    try {
      final contentType = request.headers.contentType;
      List<TextFormField> fields = [];
      List<BytesFormField> files = [];
      var boundary = contentType?.parameters['boundary'];
      if (boundary == null) {
        throw ServerError('boundary is empty', status: HttpStatus.badRequest);
      }
      var transformer = MimeMultipartTransformer(boundary);
      final parts = await transformer.bind(request).toList();

      for (var part in parts) {
        var broadCast = part.asBroadcastStream();
        final disposition = part.headers[HttpHeaders.contentDisposition];
        String? name = _getDispositionKey(disposition);
        var contentType = part.headers[HttpHeaders.contentTypeHeader] ?? 'text';

        if (contentType.startsWith('text')) {
          // If the content is text, process it as a text field.
          var res = await utf8.decoder.bind(part).join();
          TextFormField result = TextFormField(name, res);
          fields.add(result);
        } else {
          // If the content is a file, process it as a file field.
          if (!acceptFormFiles) {
            throw ServerError(
              errorString.filesNotAllowedInForm,
              status: HttpStatus.badRequest,
              trace: StackTrace.current,
              code: errorCode.filesNotAllowedInForm,
            );
          }
          // Convert the file part to bytes and save it.
          var fileBytes = await _partToBytes(broadCast, contentType);
          String? fileName = _extractFileName(disposition);

          BytesFormFileMeta meta = BytesFormFileMeta(
            contentType: contentType,
            name: fileName,
            size: fileBytes.length,
          );

          BytesFormField result = BytesFormField(name, fileBytes, meta: meta);
          files.add(result);
        }
      }
      return BytesFormData(fields: fields, files: files);
    } catch (e, s) {
      throw ServerError.fromCatch(
        msg: errorString.invalidFormBody,
        e: e,
        status: HttpStatus.badRequest,
        s: s,
        code: errorCode.invalidFormBody,
      );
    }
  }

  /// Saves the content of a file part to a file in the specified folder.
  ///
  /// [part]: The stream of data representing the file content.
  /// [contentType]: The content type of the file.
  /// [saveFolder]: The folder where the file will be saved.
  /// [fileNameOrg]: The original file name (if available).
  /// Returns the file path where the file was saved.
  Future<String> _savePartToFile(
    Stream<List<int>> part,
    String contentType,
    String saveFolder,
    String? fileNameOrg,
  ) async {
    final completer = Completer<String>();
    List<String> parts = contentType.split('/');
    late String fileExtension;
    if (parts.length != 2) {
      fileExtension = '';
    } else {
      fileExtension = '.${parts[1]}';
    }
    String fileName = fileNameOrg ?? '${dartID.generate()}$fileExtension';
    String filePath = '${saveFolder.strip('/')}/$fileName';
    File file = File(filePath);
    file.createSync(recursive: true);
    var raf = await file.open(mode: FileMode.write);

    part.listen(
      (data) {
        raf.writeFromSync(data);
      },
      onDone: () {
        raf.closeSync();
        completer.complete(filePath);
      },
      onError: (error) => completer.completeError(error),
      cancelOnError: true,
    );

    return completer.future;
  }

  /// Converts the file part to a list of bytes.
  ///
  /// [part]: The stream of data representing the file content.
  /// [contentType]: The content type of the file.
  /// Returns the list of bytes representing the file.
  Future<List<int>> _partToBytes(
    Stream<List<int>> part,
    String contentType,
  ) async {
    final completer = Completer<List<int>>();
    List<int> bytes = [];

    part.listen(
      (data) {
        bytes.addAll(data);
      },
      onDone: () {
        completer.complete(bytes);
      },
      onError: (error) => completer.completeError(error),
      cancelOnError: true,
    );

    return completer.future;
  }

  /// Receives a file from the HTTP request and saves it to the specified path.
  ///
  /// [path]: The path where the file will be saved.
  /// [throwErrorIfExist]: Whether to throw an error if the file already exists.
  /// [overrideIfExist]: Whether to override the file if it already exists.
  /// Returns the [File] that was saved.
  @override
  Future<File> receiveFile({
    required String path,
    bool throwErrorIfExist = true,
    bool overrideIfExist = false,
  }) async {
    try {
      var completer = Completer<File>();
      File file = File(path);
      bool fileExists = file.existsSync();

      // Handle file existence and behavior based on flags
      if (fileExists && throwErrorIfExist) {
        throw FileExistsError();
      } else if (fileExists && !overrideIfExist) {
        return file;
      } else if (fileExists) {
        file.deleteSync();
      }

      file.createSync(recursive: true);
      var raf = await file.open(mode: FileMode.write);

      request.listen((event) {
          raf.writeFromSync(event);
        })
        ..onError((error) {
          raf.closeSync();
          completer.completeError(error);
        })
        ..onDone(() {
          raf.closeSync();
          completer.complete(file);
        });

      var res = await completer.future;
      return res;
    } catch (e, s) {
      throw ServerError.fromCatch(
        msg: errorString.invalidFileBody,
        status: HttpStatus.badRequest,
        e: e,
        s: s,
        code: errorCode.invalidFileBody,
      );
    }
  }
}
