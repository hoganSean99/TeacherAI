import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import providing the platform-specific implementation.
import 'exam_csv_download_helper_web.dart'
    if (dart.library.io) 'exam_csv_download_helper_stub.dart' as helper;

/// Download a CSV file when running on the web platform.
///
/// On non-web platforms this function does nothing and the CSV
/// is saved using the standard file system APIs instead.
void downloadCSVWeb(String csv, String fileName) {
  if (kIsWeb) {
    helper.downloadCSVWeb(csv, fileName);
  }
}
