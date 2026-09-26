import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Contextual bottom sheet for quick 1-Tap Google or Email authentication
class AuthPromptBottomSheet extends StatefulWidget {
  final VoidCallback? onSuccess;
  final String? customTitle;
  final String? customSubtitle;

  const AuthPromptBottomSheet({
    super.key,
    this.onSuccess,
    this.customTitle,
    this.customSubtitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    String? customTitle,
    String? customSubtitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: AuthPromptBottomSheet(
          onSuccess: onSuccess,
          customTitle: customTitle,
          customSubtitle: customSubtitle,
        ),
      ),
    );
  }

  @override
  State<AuthPromptBottomSheet> createState() => _AuthPromptBottomSheetState();
}

class _AuthPromptBottomSheetState extends State<AuthPromptBottomSheet> {
  bool _isRegisterMode = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submitEmailAuth() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (_isRegisterMode) {
      context.read<AuthBloc>().add(RegisterWithEmailEvent(
            email: email,
            password: password,
            displayName: name.isNotEmpty ? name : null,
          ));
    } else {
      context.read<AuthBloc>().add(SignInWithEmailEvent(
            email: email,
            password: password,
          ));
    }
  }

  void _submitGoogleAuth() {
    context.read<AuthBloc>().add(const SignInWithGoogleEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessage = state is AuthError ? state.message : null;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            key: const Key('authPromptBottomSheet'),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: _formKey,
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

                    // Header Icon & Title
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: primary.withOpacity(0.12),
                          child: Icon(Icons.cloud_sync_rounded, color: primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.customTitle ??
                                    (_isRegisterMode
                                        ? loc.translate('auth_register_title')
                                        : loc.translate('auth_sheet_title')),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.customSubtitle ??
                                    loc.translate('auth_sheet_subtitle'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error banner
                    if (errorMessage != null) ...[
                      Container(
                        key: const Key('authErrorBanner'),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.error.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: theme.colorScheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 1-Tap Google Sign In Button
                    OutlinedButton.icon(
                      key: const Key('googleSignInButton'),
                      onPressed: isLoading ? null : _submitGoogleAuth,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: Text(
                        loc.translate('auth_sign_in_google'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider "HOẶC" / "OR"
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            loc.translate('auth_or'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mode switch tabs (Đăng nhập / Đăng ký)
                    Container(
                      key: const Key('authModeToggle'),
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              key: const Key('toggleSignInMode'),
                              onTap: () => setState(() => _isRegisterMode = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isRegisterMode
                                      ? (isDark ? const Color(0xFF383838) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !_isRegisterMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  loc.translate('auth_sign_in_tab'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !_isRegisterMode ? FontWeight.bold : FontWeight.normal,
                                    color: !_isRegisterMode
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              key: const Key('toggleRegisterMode'),
                              onTap: () => setState(() => _isRegisterMode = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isRegisterMode
                                      ? (isDark ? const Color(0xFF383838) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isRegisterMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  loc.translate('auth_register_tab'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _isRegisterMode ? FontWeight.bold : FontWeight.normal,
                                    color: _isRegisterMode
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Display Name (only in Register mode)
                    if (_isRegisterMode) ...[
                      TextFormField(
                        key: const Key('displayNameAuthField'),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: loc.translate('auth_display_name_label'),
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Email Field
                    TextFormField(
                      key: const Key('emailAuthField'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: loc.translate('auth_email_label'),
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return loc.translate('auth_email_required');
                        }
                        if (!v.contains('@')) {
                          return loc.translate('auth_email_invalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password Field
                    TextFormField(
                      key: const Key('passwordAuthField'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.translate('auth_password_label'),
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return loc.translate('auth_password_required');
                        }
                        if (v.trim().length < 6) {
                          return loc.translate('auth_password_min_length');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Submit Button
                    ElevatedButton(
                      key: const Key('submitEmailAuthButton'),
                      onPressed: isLoading ? null : _submitEmailAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              key: Key('authLoadingIndicator'),
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isRegisterMode
                                  ? loc.translate('auth_register_button')
                                  : loc.translate('auth_sign_in_button'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Continue offline button
                    TextButton(
                      key: const Key('continueOfflineButton'),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        loc.translate('auth_continue_offline'),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
