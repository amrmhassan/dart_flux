import 'dart:io';
import 'package:mime/mime.dart' as mime;
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';

class FormDataHelper {
  final FormData _formData = FormData();
  FormData get formDataRenderer {
    return _formData;
  }

  Future<void> addFile(
    File? file, {
    String? expectedMimeType,
    String fileKey = 'file[]',
  }) async {
    if (file == null) return;
    // Read the file bytes
    var imageBytes = await file.readAsBytes();
    // Determine the actual MIME type of the file
    String? actualMimeType = mime.lookupMimeType(
      file.path,
      headerBytes: imageBytes,
    );

    // Validate MIME type if expectedMimeType is provided
    if (expectedMimeType != null && actualMimeType != expectedMimeType) {
      throw Exception(
        'Invalid MIME type. Expected $expectedMimeType, but got $actualMimeType',
      );
    }

    // Add the file to the form data
    _formData.files.add(
      MapEntry(
        fileKey,
        MultipartFile.fromBytes(
          imageBytes,
          filename: file.path.split('/').last,
          contentType: MediaType.parse(
            actualMimeType ?? 'application/octet-stream',
          ),
        ),
      ),
    );
  }

  Future<void> addFiles(
    List<File>? files, {
    String? expectedMimeType,
    String fileKey = 'files[]',
  }) async {
    if (files == null) return;
    for (File file in files) {
      await addFile(file, expectedMimeType: expectedMimeType, fileKey: fileKey);
    }
  }

  void addEntry(String key, dynamic value) {
    dynamic valueCopy = value;
    if (valueCopy == null) return;
    if (valueCopy is DateTime) {
      valueCopy = valueCopy.toIso8601String();
    }
    _formData.fields.add(MapEntry(key, valueCopy.toString()));
  }

  void addEntries(Map<String, dynamic> obj) {
    for (var entry in obj.entries) {
      addEntry(entry.key, entry.value);
    }
  }

  FormDataHelper mergeWith(FormDataHelper helper) {
    FormDataHelper merged = FormDataHelper();
    var fields1 = helper.formDataRenderer.fields;
    var files1 = helper.formDataRenderer.files;
    var fields2 = _formData.fields;
    var files2 = _formData.files;
    // merging files
    merged.formDataRenderer.files.addAll(files1);
    merged.formDataRenderer.files.addAll(files2);
    // merging fields
    merged.formDataRenderer.fields.addAll(fields1);
    merged.formDataRenderer.fields.addAll(fields2);
    return merged;
  }
}
