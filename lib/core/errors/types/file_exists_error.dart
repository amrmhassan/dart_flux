import 'dart:io';
import 'package:dart_flux/core/errors/error_string.dart';
import 'package:dart_flux/core/errors/server_error.dart';

class FileExistsError extends ServerError {
  FileExistsError()
    : super(
        errorString.fileAlreadyExists,
        status: HttpStatus.conflict,
        code: errorCode.fileAlreadyExists,
      );
}
