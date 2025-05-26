import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web platform
import 'exam_csv_download_helper_web.dart' if (dart.library.io) 'exam_csv_download_helper_stub.dart';

void downloadCSVWeb(String csv, String fileName) {
  if (kIsWeb) {
    // Web implementation is in exam_csv_download_helper_web.dart
    downloadCSVWeb(csv, fileName);
  }
  // Non-web platforms will use the existing file system implementation
  // This is handled in the ExamDashboardPage's _exportCSV method
} 