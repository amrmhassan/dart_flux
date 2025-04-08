import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';

class FolderServer {
  String path;
  String alias;

  FolderServer({required this.path, required this.alias}) {
    Directory dir = Directory(path);
    if (!dir.existsSync()) {
      throw ServerError(
        'served folder not found',
        status: HttpStatus.internalServerError,
      );
    }
  }
}
