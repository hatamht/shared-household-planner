import 'package:share_plus/share_plus.dart';

/// Abstract service defining file sharing and system sheet invocation.
abstract class ShareService {
  Future<bool> shareFile({
    required String filePath,
    String? text,
    String? subject,
  });

  Future<bool> shareText({
    required String text,
    String? subject,
  });
}

/// Concrete implementation utilizing the official `share_plus` package.
class SharePlusService implements ShareService {
  const SharePlusService();

  @override
  Future<bool> shareFile({
    required String filePath,
    String? text,
    String? subject,
  }) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: subject,
      );
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      await Share.share(
        text,
        subject: subject,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Test fake recording share actions without platform channel interaction.
class FakeShareService implements ShareService {
  final List<String> sharedFiles = [];
  final List<String> sharedTexts = [];
  bool shouldSucceed = true;

  @override
  Future<bool> shareFile({
    required String filePath,
    String? text,
    String? subject,
  }) async {
    sharedFiles.add(filePath);
    if (text != null) sharedTexts.add(text);
    return shouldSucceed;
  }

  @override
  Future<bool> shareText({
    required String text,
    String? subject,
  }) async {
    sharedTexts.add(text);
    return shouldSucceed;
  }

  void reset() {
    sharedFiles.clear();
    sharedTexts.clear();
    shouldSucceed = true;
  }
}
