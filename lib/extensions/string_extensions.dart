/// Extension on String for useful string manipulations.
extension StringExtensions on String {
  /// Capitalizes the first letter of the string and makes the rest lowercase.
  /// Example: "hello world" -> "Hello world"
  String get capitalize {
    return this[0].toUpperCase() + this.substring(1).toLowerCase();
  }

  /// Strips the given string from the start or end of this string.
  /// If [all] is true, it will remove the string from both the start and end recursively.
  /// If [all] is false, it only removes the string from the start and/or end once.
  ///
  /// Example:
  /// "hello world".strip("hello") -> " world"
  /// "hello world".strip("world") -> "hello "
  String strip(String stripped, {bool all = true}) =>
      all ? _stripStringAll(this, stripped) : _stripString(this, stripped);
}

/// This helper function removes the specified [stripped] string from the start
/// and/or end of the given [text] only once.
String _stripString(String text, String stripped) {
  String copy = text;
  // Check if the text starts with the stripped string, and remove it
  if (copy.startsWith(stripped)) {
    copy = copy.substring(stripped.length);
  }

  // Check if the text ends with the stripped string, and remove it
  if (copy.endsWith(stripped)) {
    copy = copy.substring(0, copy.length - stripped.length);
  }
  return copy;
}

/// This helper function recursively removes the specified [stripped] string
/// from both the start and end of the given [text] as long as possible.
String _stripStringAll(String text, String stripped) {
  String input = text;
  String? output;

  // Continue removing the stripped string until no further changes are made
  while (true) {
    output = _stripString(input, stripped);
    if (output == input) {
      // If no changes were made, exit the loop
      break;
    } else {
      input = output;
    }
  }

  return output;
}
