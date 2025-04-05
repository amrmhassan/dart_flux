import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';

class FileExistsError extends ServerError {
  FileExistsError([String? path])
    : super('File already exists', status: HttpStatus.conflict);
}
