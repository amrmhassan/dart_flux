import 'dart:io';

ErrorString errorString = ErrorString();
ErrorCode errorCode = ErrorCode();

class ErrorString {
  // invalid body
  String invalidJsonBody = 'body content is not valid as json';
  String invalidStringBody = 'body content is not valid as string';
  String invalidBytesBody = 'body content is not valid as bytes';
  String invalidFormBody = 'body content is not valid as a form';
  String invalidFileBody = 'body content is not valid as a file';
  // invalid part of body
  String filesNotAllowedInForm = 'files aren\'t accepted in this form';
  String largeRequestSize = 'Request size exceeded';
  String unknownRequestSize =
      'Request size is unknown, please set ${HttpHeaders.contentLengthHeader} header';
  String fileAlreadyExists = 'File already exists';
}

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
}
