import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/repositories/cloud_sync_repository.dart';

class InviteCodeDialog extends StatefulWidget {
  final CloudSyncRepository cloudSyncRepository;
  final String userId;
  final String userName;
  final void Function(String projectId)? onJoined;

  const InviteCodeDialog({
    super.key,
    required this.cloudSyncRepository,
    required this.userId,
    required this.userName,
    this.onJoined,
  });

  static Future<void> show(
    BuildContext context, {
    required CloudSyncRepository cloudSyncRepository,
    required String userId,
    required String userName,
    void Function(String projectId)? onJoined,
  }) {
    return showDialog(
      context: context,
      builder: (_) => InviteCodeDialog(
        cloudSyncRepository: cloudSyncRepository,
        userId: userId,
        userName: userName,
        onJoined: onJoined,
      ),
    );
  }

  @override
  State<InviteCodeDialog> createState() => _InviteCodeDialogState();
}

class _InviteCodeDialogState extends State<InviteCodeDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final project = await widget.cloudSyncRepository.joinProjectWithInviteCode(
        inviteCode: code,
        userId: widget.userId,
        userName: widget.userName,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onJoined?.call(project.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tham gia dự án: ${project.name}'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      key: const Key('inviteCodeDialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        loc.translate('join_project_title'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.translate('join_project_subtitle'),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('inviteCodeField'),
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(text: newValue.text.toUpperCase());
              }),
            ],
            decoration: InputDecoration(
              hintText: 'DL-8899',
              labelText: loc.translate('invite_code_label'),
              prefixIcon: const Icon(Icons.key_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: _errorMessage,
            ),
            onSubmitted: (_) => _submitCode(),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancelInviteCodeButton'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.translate('cancel')),
        ),
        ElevatedButton(
          key: const Key('submitInviteCodeButton'),
          onPressed: _isLoading ? null : _submitCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(loc.translate('join_button')),
        ),
      ],
    );
  }
}
