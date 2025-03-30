class ServerError implements Exception {
  final String msg;
  final int code;
  final String? description;
  final dynamic extra;

  ServerError(this.msg, [this.code = 500, this.description, this.extra]);

  @override
  String toString() {
    return 'Error occurred ($msg), code:$code';
  }
}
