import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../split_bills/domain/entities/category_icon.dart';

/// Comprehensive Settings Screen consolidating Profile, Theme, Language,
/// Currency, Data Management, Export Options, and About information.
class SettingsScreen extends StatefulWidget {
  final bool showAppBar;
  final String? initialCurrency;
  final void Function(String)? onCurrencyChanged;
  final void Function()? onClearCache;
  final void Function()? onResetData;

  const SettingsScreen({
    super.key,
    this.showAppBar = false,
    this.initialCurrency,
    this.onCurrencyChanged,
    this.onClearCache,
    this.onResetData,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = 'EUR';
  bool _cacheCleared = false;
  bool _dataReset = false;

  final List<String> _supportedCurrencies = const ['EUR', 'USD', 'VND', 'GBP', 'JPY'];

  @override
  void initState() {
    super.initState();
    if (widget.initialCurrency != null) {
      _selectedCurrency = widget.initialCurrency!;
    } else {
      _loadCurrency();
    }
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_currency');
      if (saved != null && _supportedCurrencies.contains(saved)) {
        setState(() {
          _selectedCurrency = saved;
        });
      }
    } catch (_) {}
  }

  Future<void> _changeCurrency(String newCurrency) async {
    setState(() {
      _selectedCurrency = newCurrency;
    });
    widget.onCurrencyChanged?.call(newCurrency);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_currency', newCurrency);
    } catch (_) {}
  }

  void _handleClearCache(BuildContext context, AppLocalizations loc) {
    setState(() {
      _cacheCleared = true;
    });
    widget.onClearCache?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('cache_cleared')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleResetData(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('reset_demo_data')),
        content: Text(loc.translate('reset_demo_data_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            key: const Key('confirmResetDataButton'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _dataReset = true;
              });
              widget.onResetData?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate('data_reset_success')),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(loc.translate('confirm_delete')),
          ),
        ],
      ),
    );
  }

  void _handleExportNotice(BuildContext context, AppLocalizations loc, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${loc.translate(type)}: ${loc.translate('export_coming_soon')}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleEditProfile(BuildContext context, AppLocalizations loc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('edit_profile')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    } catch (_) {}

    LanguageProvider? languageProvider;
    try {
      languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    } catch (_) {}

    final isDark = themeProvider?.isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);
    final currentLanguageCode = languageProvider?.currentLocale.languageCode ?? 'en';

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── SECTION 1: Account Info ──────────────────────────────────────
        _buildSectionHeader(context, loc.translate('account_info')),
        const SizedBox(height: 8),
        _buildAccountCard(context, loc, isDark),
        const SizedBox(height: 20),

        // ── SECTION 2: Theme Settings ────────────────────────────────────
        _buildSectionHeader(context, loc.translate('theme_settings')),
        const SizedBox(height: 8),
        _buildThemeCard(context, loc, themeProvider, isDark),
        const SizedBox(height: 20),

        // ── SECTION 3: Preferences (Language & Currency) ─────────────────
        _buildSectionHeader(context, loc.translate('preferences')),
        const SizedBox(height: 8),
        _buildPreferencesCard(context, loc, languageProvider, currentLanguageCode, isDark),
        const SizedBox(height: 20),

        // ── SECTION 4: Export Options ────────────────────────────────────
        _buildSectionHeader(context, loc.translate('export_options')),
        const SizedBox(height: 8),
        _buildExportCard(context, loc, isDark),
        const SizedBox(height: 20),

        // ── SECTION 5: Data Management ───────────────────────────────────
        _buildSectionHeader(context, loc.translate('data_management')),
        const SizedBox(height: 8),
        _buildDataManagementCard(context, loc, isDark),
        const SizedBox(height: 20),

        // ── SECTION 6: About App ─────────────────────────────────────────
        _buildSectionHeader(context, loc.translate('about_app')),
        const SizedBox(height: 8),
        _buildAboutCard(context, loc, isDark),
        const SizedBox(height: 24),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('settings')),
          elevation: 0.5,
        ),
        body: content,
      );
    }

    return content;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AppLocalizations loc, bool isDark) {
    return Card(
      key: const Key('accountInfoCard'),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Text(
                'H',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          loc.translate('account_name'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          loc.translate('account_role_owner'),
                          key: const Key('accountRoleBadge'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'household@example.com',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('editProfileButton'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: loc.translate('edit_profile'),
              onPressed: () => _handleEditProfile(context, loc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    AppLocalizations loc,
    ThemeProvider? themeProvider,
    bool isDark,
  ) {
    return Card(
      key: const Key('themeSettingsCard'),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          RadioListTile<bool>(
            key: const Key('settingsLightModeTile'),
            title: Text(loc.translate('theme_light')),
            secondary: const Icon(Icons.light_mode),
            value: false,
            groupValue: isDark,
            onChanged: (val) {
              if (val != null) themeProvider?.setDarkMode(val);
            },
          ),
          const Divider(height: 1),
          RadioListTile<bool>(
            key: const Key('settingsDarkModeTile'),
            title: Text(loc.translate('theme_dark')),
            secondary: const Icon(Icons.dark_mode),
            value: true,
            groupValue: isDark,
            onChanged: (val) {
              if (val != null) themeProvider?.setDarkMode(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(
    BuildContext context,
    AppLocalizations loc,
    LanguageProvider? languageProvider,
    String currentLanguageCode,
    bool isDark,
  ) {
    return Card(
      key: const Key('preferencesCard'),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          // Language selection
          RadioListTile<String>(
            key: const Key('settingsEnglishTile'),
            title: Text('🇬🇧 ${loc.translate("english")}'),
            value: 'en',
            groupValue: currentLanguageCode,
            onChanged: (val) {
              if (val != null) languageProvider?.setLanguage(val);
            },
          ),
          const Divider(height: 1),
          RadioListTile<String>(
            key: const Key('settingsVietnameseTile'),
            title: Text('🇻🇳 ${loc.translate("vietnamese")}'),
            value: 'vi',
            groupValue: currentLanguageCode,
            onChanged: (val) {
              if (val != null) languageProvider?.setLanguage(val);
            },
          ),
          const Divider(height: 1),

          // Currency selector
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(
              loc.translate('default_currency'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            trailing: DropdownButton<String>(
              key: const Key('settingsCurrencyDropdown'),
              value: _selectedCurrency,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) _changeCurrency(val);
              },
              items: _supportedCurrencies.map((c) {
                final sym = currencySymbols[c] ?? c;
                return DropdownMenuItem<String>(
                  value: c,
                  child: Text('$c ($sym)', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, AppLocalizations loc, bool isDark) {
    return Card(
      key: const Key('exportOptionsCard'),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          ListTile(
            key: const Key('exportCsvTile'),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2FE),
              child: Icon(Icons.table_chart, color: Color(0xFF0284C7)),
            ),
            title: Text(loc.translate('export_csv'), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(loc.translate('export_csv_desc'), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _handleExportNotice(context, loc, 'export_csv'),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('exportPdfTile'),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626)),
            ),
            title: Text(loc.translate('export_pdf'), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(loc.translate('export_pdf_desc'), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _handleExportNotice(context, loc, 'export_pdf'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard(BuildContext context, AppLocalizations loc, bool isDark) {
    return Card(
      key: const Key('dataManagementCard'),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          ListTile(
            key: const Key('clearCacheButton'),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEF3C7),
              child: Icon(Icons.cleaning_services, color: Color(0xFFD97706)),
            ),
            title: Text(loc.translate('clear_cache'), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              _cacheCleared ? loc.translate('cache_cleared') : loc.translate('cache_size'),
              key: const Key('cacheSizeText'),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _cacheCleared
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.delete_sweep_outlined),
            onTap: () => _handleClearCache(context, loc),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('resetDataButton'),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.restore, color: Color(0xFFDC2626)),
            ),
            title: Text(loc.translate('reset_demo_data'), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(loc.translate('reset_demo_data_desc'), style: const TextStyle(fontSize: 12)),
            trailing: _dataReset
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.refresh),
            onTap: () => _handleResetData(context, loc),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, AppLocalizations loc, bool isDark) {
    return Card(
      key: const Key('aboutAppCard'),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.home_work, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('app_name'),
                      key: const Key('appNameText'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.translate('app_version'),
                      key: const Key('appVersionText'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('developed_by'),
                  key: const Key('developedByText'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const Icon(Icons.verified, size: 16, color: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
