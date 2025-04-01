import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_flux/constants/global.dart';
import 'package:dart_flux/core/errors/file_exists_error.dart';
import 'package:dart_flux/core/server/routing/interface/multi_part_interface.dart';
import 'package:dart_flux/core/server/routing/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/routing/models/form_data.dart';
import 'package:dart_flux/core/server/routing/models/form_field.dart';
import 'package:dart_flux/extensions/string_utils.dart';
import 'package:mime/mime.dart';

class FluxMultiPart implements MultiPartInterface {
  @override
  HttpRequest request;

  FluxMultiPart(this.request);

  @override
  Future<FormData> readForm({
    required String saveFolder,
    bool acceptFormFiles = true,
  }) async {
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
        // this is a text
        var res = await utf8.decoder.bind(part).join();
        TextFormField result = TextFormField(name, res);
        fields.add(result);
      } else {
        if (!acceptFormFiles) {
          throw Exception('files aren\'t accepted in this form');
        }
        // this should be a stream of a file
        var filePath = await _savePartToFile(
          broadCast,
          contentType,
          saveFolder,
        );
        FileFormField result = FileFormField(name, filePath);
        files.add(result);
      }
    }
    FormData formData = FormData(fields: fields, files: files);
    return formData;
  }

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

  @override
  Future<BytesFormData> readFormBytes({bool acceptFormFiles = true}) async {
    final contentType = request.headers.contentType;
    List<TextFormField> fields = [];
    List<BytesFormField> files = [];
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
        // this is a text
        var res = await utf8.decoder.bind(part).join();
        TextFormField result = TextFormField(name, res);
        fields.add(result);
      } else {
        // this should be a stream of a file
        if (!acceptFormFiles) {
          throw Exception('files aren\'t accepted in this form');
        }
        var filePath = await _partToBytes(broadCast, contentType);
        BytesFormField result = BytesFormField(name, filePath);
        files.add(result);
      }
    }
    BytesFormData form = BytesFormData(fields: fields, files: files);
    return form;
  }

  Future<String> _savePartToFile(
    Stream<List<int>> part,
    String contentType,
    String saveFolder,
  ) async {
    final completer = Completer<String>();
    List<String> parts = contentType.split('/');
    late String fileExtension;
    if (parts.length != 2) {
      fileExtension = '';
    } else {
      fileExtension = '.${parts[1]}';
    }
    String fileName = dartID.generate();
    String filePath = '${saveFolder.strip('/')}/$fileName$fileExtension';
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

  @override
  Future<File> receiveFile({
    required String path,
    bool throwErrorIfExist = true,
    bool overrideIfExist = false,
  }) async {
    var completer = Completer<File>();

    File file = File(path);
    if (file.existsSync() && throwErrorIfExist) {
      throw FileExistsError();
    } else if (file.existsSync() && !overrideIfExist) {
      return file;
    } else if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    var raf = await file.open(mode: FileMode.write);

    request
        .listen((event) {
          raf.writeFromSync(event);
        })
        .onDone(() {
          raf.closeSync();
          completer.complete(file);
        });

    return completer.future;
  }
}
