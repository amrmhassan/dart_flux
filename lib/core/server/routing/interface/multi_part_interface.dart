import 'dart:io';

import 'package:dart_flux/core/server/routing/models/bytes_form_data.dart';
import 'package:dart_flux/core/server/routing/models/form_data.dart';

abstract class MultiPartInterface {
  late HttpRequest request;

  Future<FormData> readForm({required String saveFolder, bool acceptFormFiles});
  Future<BytesFormData> readFormBytes({bool acceptFormFiles});
  Future<File> receiveFile({
    required String path,
    bool throwErrorIfExist = true,
    bool overrideIfExist = false,
  });
}
