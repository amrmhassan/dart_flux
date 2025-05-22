import 'dart:io';

import 'package:dart_flux/core/errors/server_error.dart';

class NotFoundError extends ServerError {
  final String msg;
  NotFoundError(this.msg) : super(msg, status: HttpStatus.notFound);
}
