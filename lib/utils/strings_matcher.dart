class StringsMatcher {
  /// Calculates the similarity percentage between two strings
  static double compare(String s1, String s2) {
    if (s1 == s2) return 100.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshtein(s1.toLowerCase(), s2.toLowerCase());
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return ((1.0 - (distance / maxLength)) * 100).clamp(0.0, 100.0);
  }

  /// Levenshtein Distance Algorithm
  static int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;

    List<List<int>> dp = List.generate(
      m + 1,
      (_) => List<int>.filled(n + 1, 0),
    );

    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;

        dp[i][j] = [
          dp[i - 1][j] + 1, // deletion
          dp[i][j - 1] + 1, // insertion
          dp[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[m][n];
  }
}
