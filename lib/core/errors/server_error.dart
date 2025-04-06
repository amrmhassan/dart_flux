/// Responsible for handling all errors thrown by the Flux framework.
/// This error will be mapped into a structured JSON response returned to the client.
class ServerError implements Exception {
  /// A message describing the error. Can be a string or another object.
  final Object msg;

  /// HTTP status code to return with the response (default is 500).
  final int? status;

  /// An optional detailed description of the error (e.g., the caught exception).
  final Object? description;

  /// Any additional data relevant to the error (e.g., debug info).
  final dynamic extra;

  /// The stack trace associated with the error, if available.
  final StackTrace? trace;

  /// A machine-readable error code that uniquely identifies this error type.
  final String? code;

  /// Constructor for manually creating a ServerError instance.
  ServerError(
    this.msg, {
    this.status = 500,
    this.description,
    this.extra,
    this.trace,
    this.code,
  });

  /// Factory method to wrap any thrown object in a [ServerError].
  /// If the caught error [e] is already a [ServerError], it will return it as-is.
  /// Otherwise, it creates a new [ServerError] using the provided message and exception.
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

  /// Returns a brief string representation of the error for logging or debugging.
  @override
  String toString() {
    return 'Error occurred ($msg), code:$status';
  }

  /// Serializes the error into a JSON-compatible map.
  /// This is useful for sending structured error responses to clients.
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
