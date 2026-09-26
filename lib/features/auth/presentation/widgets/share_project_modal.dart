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
            // 6-character code box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
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
                  const SizedBox(height: 8),
                  SelectableText(
                    _invite!.inviteCode,
                    key: const Key('inviteCodeDisplay'),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('copyInviteCodeButton'),
                    onPressed: () => _copyCode(loc),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(loc.translate('copy_code_button')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('shareInviteCodeButton'),
                    onPressed: () => _copyCode(loc),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(loc.translate('share_code_button')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
