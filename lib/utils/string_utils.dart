class StringUtils {
  static String? combineStrings(String? first, String? second) {
    if (first == null && second == null) return null;
    return (first ?? '') + (second ?? '');
  }
}
