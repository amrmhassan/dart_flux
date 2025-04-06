// ignore_for_file: constant_identifier_names

import 'package:dart_flux/core/errors/server_error.dart';

/// Enum representing HTTP methods.
enum HttpMethod {
  /// HTTP GET method, typically used for retrieving resources.
  get,

  /// HTTP POST method, used for submitting data.
  post,

  /// HTTP PUT method, used for updating resources.
  put,

  /// HTTP DELETE method, used for removing resources.
  delete,

  /// HTTP HEAD method, used to retrieve metadata (headers) of a resource.
  head,

  /// HTTP CONNECT method, used for establishing a network connection.
  connect,

  /// HTTP OPTIONS method, used to describe the communication options for the target resource.
  options,

  /// HTTP TRACE method, used for diagnostic purposes to trace the path of the request.
  trace,

  /// HTTP PATCH method, used for partial updates to a resource.
  patch,
}

/// Converts an HTTP method string to an [HttpMethod] enum.
///
/// This function takes an HTTP method as a string (e.g., "GET", "POST")
/// and returns the corresponding [HttpMethod] enum value.
/// If the provided string doesn't match any of the HTTP methods,
/// it throws a [ServerError].
///
/// Example:
/// ```dart
/// methodFromString('GET'); // returns HttpMethod.get
/// methodFromString('POST'); // returns HttpMethod.post
/// ```
///
/// Throws:
/// [ServerError] if the string doesn't match any HTTP method.
HttpMethod methodFromString(String httpMethod) {
  var values = HttpMethod.values;

  // Find the index of the matching method (case insensitive)
  int index = values.indexWhere(
    (e) => e.name.toLowerCase() == httpMethod.toLowerCase(),
  );

  // If no matching method is found, throw an error
  if (index == -1) {
    throw ServerError('method $httpMethod not found');
  }

  // Return the corresponding [HttpMethod] enum
  return values[index];
}
