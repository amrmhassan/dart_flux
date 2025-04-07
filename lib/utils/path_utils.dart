import 'package:dart_flux/core/server/routing/interface/base_path.dart';
import 'package:dart_flux/utils/string_utils.dart';

class PathUtils {
  /// Checks if the [requestPath] matches the [handlerPath].
  /// Supports exact matches, path parameters (e.g., `/user/:id`), and wildcards (`*`).
  ///
  /// - Wildcard `*` matches any path beyond that point.
  /// - Path parameters like `:param` match any value at that segment.
  ///
  /// Returns `true` if the paths match, otherwise `false`.
  static bool pathMatches({
    required String requestPath,
    required String handlerPath,
  }) {
    // Split both paths into segments (e.g., `/user/123` -> `['user', '123']`)
    List<String> requestSegments = requestPath.split('/');
    List<String> handlerSegments = handlerPath.split('/');

    for (int i = 0; i < handlerSegments.length; i++) {
      // Wildcard `*` matches everything beyond this point
      String handlerSegment = handlerSegments[i];
      if (handlerSegment == '*') return true; // Matches anything

      // If the request path has fewer segments than the handler path, it's not a match
      if (i >= requestSegments.length) return false;

      // Exact match or parameterized match `:param`
      String requestSegment = requestSegments[i];
      if (handlerSegment != requestSegment && !handlerSegment.startsWith(':')) {
        return false; // Segment mismatch and no parameter
      }
    }

    // Ensure the request path has the same number of segments as the handler path
    return requestSegments.length == handlerSegments.length;
  }

  /// Extracts path parameters from a [requestPath] based on the [handlerPath].
  /// Example: `/user/:id` and `/user/123` -> `{id: '123'}`
  ///
  /// - Parameters are extracted from segments that start with `:`.
  /// - Wildcard `*` captures all remaining segments.
  static Map<String, String> extractParams(
    String requestPath,
    String? handlerPath,
  ) {
    if (handlerPath == null)
      return {}; // Return empty map if handler path is null

    // Split both paths into segments
    List<String> requestSegments =
        requestPath.split('/').where((segment) => segment.isNotEmpty).toList();
    List<String> handlerSegments =
        handlerPath.split('/').where((segment) => segment.isNotEmpty).toList();

    Map<String, String> params = {};
    bool catchAllStarted = false; // Flag to handle wildcard "*"

    for (int i = 0; i < handlerSegments.length; i++) {
      if (handlerSegments[i].startsWith(':')) {
        // Extract parameter name (e.g., :id -> id)
        String paramName = handlerSegments[i].substring(1); // Remove ':'
        if (i < requestSegments.length) {
          params[paramName] = requestSegments[i]; // Map the value
        }
      } else if (handlerSegments[i] == '*') {
        // Handle the wildcard "*" which captures all remaining segments
        catchAllStarted = true;
        params['*'] = requestSegments
            .sublist(i) // Capture all remaining segments
            .join('/'); // Join them as a single string
        break; // No need to process further, the rest of the path is captured
      }
    }

    // If no wildcard was found but the request has extra segments, capture them
    if (!catchAllStarted && requestSegments.length > handlerSegments.length) {
      params['*'] = requestSegments.sublist(handlerSegments.length).join('/');
    }

    return params;
  }

  /// Combines [parentPath] and [entityPath] into a final path.
  /// If either is null, it returns the other. If both are null, it returns null.
  /// Example:
  /// - `parentPath = '/api'`, `entityPath = '/user'` -> `/api/user`
  static String? finalPath(BasePath? parent, String? path) {
    if (parent == null) return path;
    String? parentPath = parent.pathTemplate;
    String? res = StringUtils.combineStrings(parentPath, path);
    String? finalRes = finalPath(parent.parent, res);
    return finalRes;
  }
}
