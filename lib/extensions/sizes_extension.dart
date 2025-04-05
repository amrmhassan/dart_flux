/// this assumes that the size is in bytes
/// this extension is used to convert bytes to KB, MB, GB, TB
extension ByteSizeExtension on int {
  /// this assumes that the size is in bytes
  double get toKB => this / 1024;

  /// this assumes that the size is in bytes
  double get toMB => this / (1024 * 1024);

  /// this assumes that the size is in bytes
  double get toGB => this / (1024 * 1024 * 1024);

  /// this assumes that the size is in bytes
  double get toTB => this / (1024 * 1024 * 1024 * 1024);

  /// this assumes that the size is in bytes
  String toReadableSize({int decimals = 2}) {
    final size = this;
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = size.toDouble();
    int index = 0;

    while (value >= 1024 && index < suffixes.length - 1) {
      value /= 1024;
      index++;
    }

    return '${value.toStringAsFixed(decimals)} ${suffixes[index]}';
  }
}
