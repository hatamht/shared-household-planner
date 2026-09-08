import 'package:flutter/material.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_icon.dart';
import '../../../../core/localization/app_localizations.dart';

/// Modal bottom sheet for adding a new category with suggestions, icon picker & color palette
class AddCategoryBottomSheet extends StatefulWidget {
  final List<CategoryIconItem> existingCategories;

  const AddCategoryBottomSheet({
    Key? key,
    required this.existingCategories,
  }) : super(key: key);

  static Future<CategoryIconItem?> show(
    BuildContext context, {
    required List<CategoryIconItem> existingCategories,
  }) {
    return showModalBottomSheet<CategoryIconItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddCategoryBottomSheet(
        existingCategories: existingCategories,
      ),
    );
  }

  @override
  State<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  late TextEditingController _nameController;
  String _selectedEmoji = '🏷️';
  IconData? _selectedIconData;
  late String _selectedColorHex;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedColorHex = presetCategoryColors.first;
    _selectedIconData = suggestedCategoryIcons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applySuggestion(CategorySuggestion suggestion, AppLocalizations loc) {
    setState(() {
      final isVi = loc.locale.languageCode == 'vi';
      _nameController.text = isVi ? suggestion.nameVi : suggestion.nameEn;
      _selectedEmoji = suggestion.emoji;
      _selectedIconData = suggestion.iconData;
      _selectedColorHex = suggestion.colorHex;
      _errorMessage = null;
    });
  }

  void _saveCategory(AppLocalizations loc) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = loc.translate('category_name_required');
      });
      return;
    }

    final id = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

    final exists = widget.existingCategories.any(
      (c) => c.id.toLowerCase() == id || c.nameKey.toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      setState(() {
        _errorMessage = loc.translate('category_already_exists');
      });
      return;
    }

    final newCategory = CategoryIconItem(
      id: id,
      icon: _selectedEmoji,
      nameKey: name,
      colorHex: _selectedColorHex,
    );

    Navigator.pop(context, newCategory);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isVi = loc.locale.languageCode == 'vi';
    final activeColor = colorFromHex(_selectedColorHex);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('add_category'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  key: const Key('cancelCategoryButton'),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // ── Suggestions List (5-8 popular presets) ──────
            Text(
              loc.translate('suggestions'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popularCategorySuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = popularCategorySuggestions[index];
                  final itemColor = colorFromHex(item.colorHex);
                  return ActionChip(
                    key: Key('suggestion_${item.id}'),
                    avatar: Text(item.emoji, style: const TextStyle(fontSize: 14)),
                    label: Text(
                      isVi ? item.nameVi : item.nameEn,
                      style: TextStyle(
                        fontSize: 12,
                        color: itemColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: itemColor.withOpacity(0.12),
                    side: BorderSide(color: itemColor.withOpacity(0.5)),
                    onPressed: () => _applySuggestion(item, loc),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Category Name Field ─────────────────────────
            TextField(
              key: const Key('newCategoryNameField'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: loc.translate('category_name'),
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedEmoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                errorText: _errorMessage,
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            const SizedBox(height: 16),

            // ── Icon Picker (20+ Material IconData) ──────────
            Text(
              loc.translate('choose_icon'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggestedCategoryIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final icon = suggestedCategoryIcons[index];
                  final isSelected = icon == _selectedIconData;
                  return InkWell(
                    key: Key('icon_option_${icon.codePoint}'),
                    onTap: () {
                      setState(() {
                        _selectedIconData = icon;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withOpacity(0.2)
                            : Colors.grey.shade100,
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? activeColor : Colors.grey.shade700,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Color Picker (12+ Preset Colors) ─────────────
            Text(
              loc.translate('choose_color'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: presetCategoryColors.map((hex) {
                final swatchColor = colorFromHex(hex);
                final isSelected = hex == _selectedColorHex;
                return GestureDetector(
                  key: Key('color_swatch_$hex'),
                  onTap: () {
                    setState(() {
                      _selectedColorHex = hex;
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: swatchColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: swatchColor.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Save Button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('saveCategoryButton'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _saveCategory(loc),
                child: Text(
                  loc.translate('save_category'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
