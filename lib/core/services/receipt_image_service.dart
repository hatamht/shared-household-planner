import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ReceiptImageService {
  static Directory? _overrideDirectory;
  static const _uuid = Uuid();

  /// Allows unit and widget tests to inject a temporary directory.
  static void setOverrideDirectory(Directory? dir) {
    _overrideDirectory = dir;
  }

  /// Gets the directory where receipts are stored.
  static Future<Directory> getReceiptsDirectory() async {
    if (_overrideDirectory != null) {
      if (!_overrideDirectory!.existsSync()) {
        _overrideDirectory!.createSync(recursive: true);
      }
      return _overrideDirectory!;
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(docsDir.path, 'receipts'));
      if (!receiptsDir.existsSync()) {
        receiptsDir.createSync(recursive: true);
      }
      return receiptsDir;
    } catch (_) {
      // Fallback for tests or environments where path_provider is not mocked
      final tempDir = Directory(p.join(Directory.systemTemp.path, 'shared_receipts'));
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }
      return tempDir;
    }
  }

  /// Saves a receipt from a local file path into the persistent app directory.
  static Future<String> saveReceiptFromPath(String sourcePath, {String? billId}) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      return sourcePath;
    }

    final receiptsDir = await getReceiptsDirectory();
    final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = billId != null && billId.isNotEmpty ? 'receipt_${billId}_' : 'receipt_';
    final fileName = '${prefix}${timestamp}_${_uuid.v4().substring(0, 8)}$ext';
    final destination = File(p.join(receiptsDir.path, fileName));

    await sourceFile.copy(destination.path);
    return destination.path;
  }

  /// Saves raw image bytes into the receipt directory.
  static Future<String> saveReceiptBytes(
    Uint8List bytes, {
    String? billId,
    String extension = '.jpg',
  }) async {
    final receiptsDir = await getReceiptsDirectory();
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = billId != null && billId.isNotEmpty ? 'receipt_${billId}_' : 'receipt_';
    final fileName = '${prefix}${timestamp}_${_uuid.v4().substring(0, 8)}$ext';
    final destination = File(p.join(receiptsDir.path, fileName));

    await destination.writeAsBytes(bytes, flush: true);
    return destination.path;
  }

  /// Deletes a receipt image by path.
  static Future<bool> deleteReceipt(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Checks if an image file exists at the given path.
  static bool receiptExists(String? path) {
    if (path == null || path.isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Returns total bytes consumed by all saved receipts.
  static Future<int> getTotalReceiptStorageBytes() async {
    final dir = await getReceiptsDirectory();
    if (!dir.existsSync()) return 0;

    int totalBytes = 0;
    try {
      final entities = dir.listSync(recursive: false);
      for (final entity in entities) {
        if (entity is File) {
          totalBytes += entity.lengthSync();
        }
      }
    } catch (_) {}
    return totalBytes;
  }

  /// Formats bytes to human-readable size string (e.g. 1.2 MB, 450 KB).
  static String formatStorageSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    }
  }

  /// Returns total count of saved receipt image files.
  static Future<int> getReceiptCount() async {
    final dir = await getReceiptsDirectory();
    if (!dir.existsSync()) return 0;
    try {
      return dir.listSync(recursive: false).whereType<File>().length;
    } catch (_) {
      return 0;
    }
  }

  /// Clears all files from receipts directory.
  static Future<void> clearAllReceipts() async {
    final dir = await getReceiptsDirectory();
    if (dir.existsSync()) {
      try {
        final files = dir.listSync(recursive: false);
        for (final f in files) {
          if (f is File) {
            try {
              f.deleteSync();
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }

  /// Validates whether a file extension corresponds to a supported image.
  static bool isValidImageExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.webp' ||
        ext == '.heic' ||
        ext == '.heif';
  }
}
