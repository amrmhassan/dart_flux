/// responsible for handling all errors thrown by flux framework and will be mapped into the response returned to the client
class ServerError implements Exception {
  final String msg;
  final int? code;
  final String? description;
  final dynamic extra;

  ServerError(this.msg, [this.code = 500, this.description, this.extra]);

  @override
  String toString() {
    return 'Error occurred ($msg), code:$code';
  }

  Map<String, dynamic> toJson() {
    return {
      'msg': msg,
      'code': code,
      'description': description,
      'extra': extra,
    };
  }
}
