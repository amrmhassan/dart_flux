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
    String handlerPath,
  ) {
    List<String> requestSegments = requestPath.split('/');
    List<String> handlerSegments = handlerPath.split('/');
    Map<String, String> params = {};

    for (int i = 0; i < handlerSegments.length; i++) {
      if (handlerSegments[i].startsWith(':')) {
        String paramName = handlerSegments[i].substring(1); // Remove ':'
        params[paramName] = requestSegments[i];
      }
    }

    return params;
  }
}
