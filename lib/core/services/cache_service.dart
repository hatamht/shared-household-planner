import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'receipt_image_service.dart';

/// Service responsible for measuring and cleaning temporary cache files
/// such as exported CSV/PDF reports, image picker temporary files, and receipt caches.
class CacheService {
  final Future<Directory> Function()? getTempDir;

  const CacheService({this.getTempDir});

  /// Calculates the actual cache size in bytes from the temporary directory
  /// and any stored receipt image assets.
  Future<int> getCacheSizeBytes() async {
    int totalBytes = 0;
    try {
      final tempDir = getTempDir != null
          ? await getTempDir!()
          : await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        totalBytes += _calculateDirSize(tempDir);
      }
    } catch (_) {}

    try {
      totalBytes += await ReceiptImageService.getTotalReceiptStorageBytes();
    } catch (_) {}

    return totalBytes;
  }

  int _calculateDirSize(Directory dir) {
    int size = 0;
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          try {
            size += entity.lengthSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return size;
  }

  /// Formats bytes into a human-friendly string (e.g. 0 KB, 450 KB, 1.2 MB).
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
  }

  /// Cleans all temporary export files, cache files, and receipt images.
  Future<void> clearCache() async {
    try {
      final tempDir = getTempDir != null
          ? await getTempDir!()
          : await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entities = tempDir.listSync(recursive: false);
        for (final entity in entities) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}

    try {
      await ReceiptImageService.clearAllReceipts();
    } catch (_) {}
  }
}
