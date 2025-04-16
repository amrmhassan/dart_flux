import 'dart:io';

/// Global instances to access error strings and codes across the project.
ErrorString errorString = ErrorString();
ErrorCode errorCode = ErrorCode();

/// Contains descriptive human-readable error messages for various types of request body errors.
/// Use these when showing error details in API responses or logs.
class ErrorString {
  // Errors related to invalid request body types
  String invalidJsonBody = 'body content is not valid as json';
  String invalidStringBody = 'body content is not valid as string';
  String invalidBytesBody = 'body content is not valid as bytes';
  String invalidFormBody = 'body content is not valid as a form';
  String invalidFileBody = 'body content is not valid as a file';

  // Errors related to request constraints or unexpected inputs
  String filesNotAllowedInForm = 'files aren\'t accepted in this form';
  String largeRequestSize = 'Request size exceeded';
  String unknownRequestSize =
      'Request size is unknown, please set ${HttpHeaders.contentLengthHeader} header';
  String fileAlreadyExists = 'File already exists';
  String jwtExpired = 'JWT Expired';
  String invalidToken = 'invalid token';
  String loginAgain =
      'Refresh token is invalid or expired. Please log in again.';
}

/// Provides corresponding error codes for each error defined in [ErrorString].
/// These codes are useful for consistent machine-readable error reporting in APIs.
class ErrorCode implements ErrorString {
  @override
  String filesNotAllowedInForm = 'files-not-allowed-in-form';

  @override
  String invalidBytesBody = 'invalid-bytes-body';

  @override
  String invalidFileBody = 'invalid-file-body';

  @override
  String invalidFormBody = 'invalid-form-body';

  @override
  String invalidJsonBody = 'invalid-json-body';

  @override
  String invalidStringBody = 'invalid-string-body';

  @override
  String largeRequestSize = 'large-request-size';

  @override
  String unknownRequestSize = 'unknown-request-size';

  @override
  String fileAlreadyExists = 'file-already-exists';

  @override
  String jwtExpired = 'jwt-expired';

  @override
  String invalidToken = 'invalid-token';

  @override
  String loginAgain = 'login-again';
}
