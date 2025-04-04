class PathUtils {
  static bool pathMatches({
    required String requestPath,
    required String handlerPath,
  }) {
    List<String> requestSegments = requestPath.split('/');
    List<String> handlerSegments = handlerPath.split('/');

    for (int i = 0; i < handlerSegments.length; i++) {
      // Wildcard `*` matches everything beyond this point
      String handlerSegment = handlerSegments[i];
      if (handlerSegment == '*') return true; // Matches anything

      // If request has fewer segments than handler, it's not a match
      if (i >= requestSegments.length) return false;

      // Exact segment match or parameterized match `:param`
      String requestSegment = requestSegments[i];
      if (handlerSegment != requestSegment && !handlerSegment.startsWith(':')) {
        return false;
      }
    }

    // If the request has more segments than handler, it's not a match
    return requestSegments.length == handlerSegments.length;
  }

  /// Extracts path parameters (e.g., `/user/:id` → `/user/123` returns `{id: 123}`)
  static Map<String, String> extractParams(
    String requestPath,
    String? handlerPath,
  ) {
    if (handlerPath == null) return {};

    // Split paths into segments
    List<String> requestSegments =
        requestPath.split('/').where((segment) => segment.isNotEmpty).toList();
    List<String> handlerSegments =
        handlerPath.split('/').where((segment) => segment.isNotEmpty).toList();

    Map<String, String> params = {};
    bool catchAllStarted = false; // Flag to handle * wildcard

    for (int i = 0; i < handlerSegments.length; i++) {
      if (handlerSegments[i].startsWith(':')) {
        // Extract parameter name
        String paramName = handlerSegments[i].substring(1); // Remove ':'
        if (i < requestSegments.length) {
          params[paramName] = requestSegments[i];
        }
      } else if (handlerSegments[i] == '*') {
        // Handle the wildcard "*" by capturing the rest of the path
        catchAllStarted = true;
        params['*'] = requestSegments
            .sublist(i)
            .join('/'); // Join the remaining path segments
        break; // No need to continue once we've captured the rest of the path
      }
    }

    // If catch-all is started but no wildcard was found, capture all remaining path parts
    if (!catchAllStarted && requestSegments.length > handlerSegments.length) {
      params['*'] = requestSegments.sublist(handlerSegments.length).join('/');
    }

    return params;
  }

  static String? finalPath(String? basePath, String? entityPath) {
    return entityPath == null && basePath == null
        ? null
        : (basePath ?? '') + (entityPath ?? '');
  }
}
