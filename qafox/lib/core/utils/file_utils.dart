class AppFileUtils {
  const AppFileUtils._();

  static String getFileSizeString(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  static String getFileExtension(String path) {
    final idx = path.lastIndexOf('.');
    if (idx < 0) return '';
    return path.substring(idx + 1).toLowerCase();
  }

  static bool isImage(String path) {
    final ext = getFileExtension(path);
    return ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'].contains(ext);
  }

  static bool isVideo(String path) {
    final ext = getFileExtension(path);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }
}
