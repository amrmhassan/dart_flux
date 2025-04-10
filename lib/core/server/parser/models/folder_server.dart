import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';
import 'package:dart_flux/extensions/string_extensions.dart';

class FolderServer {
  String path;
  String alias;

  FolderServer({required this.path, this.alias = ''}) {
    path = path.strip('/');
    Directory dir = Directory(path);
    if (!dir.existsSync()) {
      throw ServerError(
        'served folder not found',
        status: HttpStatus.internalServerError,
      );
    }
  }
}
