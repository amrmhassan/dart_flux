/// responsible for handling all errors thrown by flux framework and will be mapped into the response returned to the client
class ServerError implements Exception {
  final Object msg;
  final int? status;
  final Object? description;
  final dynamic extra;
  final StackTrace? trace;
  final String? code;

  ServerError(
    this.msg, {
    this.status = 500,
    this.description,
    this.extra,
    this.trace,
    this.code,
  });

  static ServerError fromCatch({
    required Object msg,
    required Object e,
    int? status,
    StackTrace? s,
    String? code,
  }) {
    if (e is ServerError) {
      return e;
    } else {
      return ServerError(
        msg,
        status: status,
        description: e,
        trace: s,
        code: code,
      );
    }
  }

  @override
  String toString() {
    return 'Error occurred ($msg), code:$status';
  }

  Map<String, dynamic> toJson() {
    StackTrace trace = this.trace ?? StackTrace.current;
    return {
      'msg': msg.toString(),
      'code': code,
      'status': status,
      'description': description?.toString(),
      'extra': extra,
      'stack': trace.toString(),
    };
  }
}
