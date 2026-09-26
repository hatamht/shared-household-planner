import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/cloud_schema.dart';
import '../../domain/repositories/cloud_sync_repository.dart';

class ShareProjectModal extends StatefulWidget {
  final String projectId;
  final String projectName;
  final String userId;
  final CloudSyncRepository cloudSyncRepository;

  const ShareProjectModal({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.userId,
    required this.cloudSyncRepository,
  });

  static Future<void> show(
    BuildContext context, {
    required String projectId,
    required String projectName,
    required String userId,
    required CloudSyncRepository cloudSyncRepository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareProjectModal(
        projectId: projectId,
        projectName: projectName,
        userId: userId,
        cloudSyncRepository: cloudSyncRepository,
      ),
    );
  }

  @override
  State<ShareProjectModal> createState() => _ShareProjectModalState();
}

class _ShareProjectModalState extends State<ShareProjectModal> {
  ShareInvite? _invite;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrCreateInvite();
  }

  Future<void> _loadOrCreateInvite() async {
    try {
      final invite = await widget.cloudSyncRepository.createShareInvite(
        projectId: widget.projectId,
        userId: widget.userId,
      );
      if (mounted) {
        setState(() {
          _invite = invite;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _copyCode(AppLocalizations loc) {
    if (_invite == null) return;
    Clipboard.setData(ClipboardData(text: _invite!.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('invite_code_copied')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyLink(AppLocalizations loc) {
    if (_invite == null) return;
    final link = 'https://homesplit.app/join?code=${_invite!.inviteCode}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('share_link_copied')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      key: const Key('shareProjectModal'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              loc.translate('share_project_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.projectName,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ] else if (_invite != null) ...[
              // QR Code representation
              Center(
                child: Container(
                  key: const Key('qrCodeContainer'),
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _QrMatrixPainter(code: _invite!.inviteCode),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6-character code box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      loc.translate('invite_code_instruction'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _invite!.inviteCode,
                      key: const Key('inviteCodeDisplay'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'homesplit.app/join?code=${_invite!.inviteCode}',
                      key: const Key('shareLinkText'),
                      style: TextStyle(
                        fontSize: 11,
                        color: primary.withOpacity(0.8),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('copyInviteCodeButton'),
                      onPressed: () => _copyCode(loc),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(loc.translate('copy_code_button'), style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('copyShareLinkButton'),
                      onPressed: () => _copyLink(loc),
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: Text(loc.translate('copy_link_button'), style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('shareInviteCodeButton'),
                  onPressed: () => _copyCode(loc),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(loc.translate('share_code_button'), style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple stylized QR matrix painter for QR code preview
class _QrMatrixPainter extends CustomPainter {
  final String code;
  const _QrMatrixPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    // Draw 3 corner finder patterns
    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, 26, 26), paint);
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(x + 4, y + 4, 18, 18), whitePaint);
      canvas.drawRect(Rect.fromLTWH(x + 8, y + 8, 10, 10), paint);
    }

    drawFinder(0, 0); // top-left
    drawFinder(size.width - 26, 0); // top-right
    drawFinder(0, size.height - 26); // bottom-left

    // Decorative data grid
    final dotPaint = Paint()..color = Colors.black87;
    final hash = code.hashCode;
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        // Skip corner finder areas
        if ((r < 3 && c < 3) || (r < 3 && c > 3) || (r > 3 && c < 3)) continue;
        if (((hash >> (r * 2 + c)) & 1) == 1) {
          final cx = 14.0 + c * 13.0;
          final cy = 14.0 + r * 13.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: 7, height: 7),
              const Radius.circular(2),
            ),
            dotPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) =>
      oldDelegate.code != code;
}
