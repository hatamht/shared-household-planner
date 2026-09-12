import 'package:flutter/material.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_icon.dart';
import '../../../../core/localization/app_localizations.dart';

enum CategoryEditAction { updated, deleted }

class CategoryEditResult {
  final CategoryEditAction action;
  final CategoryIconItem originalCategory;
  final CategoryIconItem? updatedCategory;

  const CategoryEditResult({
    required this.action,
    required this.originalCategory,
    this.updatedCategory,
  });

  factory CategoryEditResult.updated({
    required CategoryIconItem originalCategory,
    required CategoryIconItem updatedCategory,
  }) {
    return CategoryEditResult(
      action: CategoryEditAction.updated,
      originalCategory: originalCategory,
      updatedCategory: updatedCategory,
    );
  }

  factory CategoryEditResult.deleted({
    required CategoryIconItem originalCategory,
  }) {
    return CategoryEditResult(
      action: CategoryEditAction.deleted,
      originalCategory: originalCategory,
    );
  }
}

/// Modal bottom sheet for editing and deleting an existing category
class EditCategoryBottomSheet extends StatefulWidget {
  final CategoryIconItem category;
  final List<CategoryIconItem> existingCategories;
  final bool isDefaultCategory;

  const EditCategoryBottomSheet({
    Key? key,
    required this.category,
    required this.existingCategories,
    this.isDefaultCategory = false,
  }) : super(key: key);

  static Future<CategoryEditResult?> show(
    BuildContext context, {
    required CategoryIconItem category,
    required List<CategoryIconItem> existingCategories,
    bool? isDefaultCategory,
  }) {
    final isDefault = isDefaultCategory ??
        defaultCategoryIcons.any((item) => item.id == category.id);

    return showModalBottomSheet<CategoryEditResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditCategoryBottomSheet(
        category: category,
        existingCategories: existingCategories,
        isDefaultCategory: isDefault,
      ),
    );
  }

  @override
  State<EditCategoryBottomSheet> createState() => _EditCategoryBottomSheetState();
}

class _EditCategoryBottomSheetState extends State<EditCategoryBottomSheet> {
  late TextEditingController _nameController;
  late String _selectedEmoji;
  IconData? _selectedIconData;
  late String _selectedColorHex;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.category.icon;
    _selectedColorHex = widget.category.colorHex;

    // Pre-fill name controller (will also be localized in didChangeDependencies if translation key exists)
    _nameController = TextEditingController(text: widget.category.nameKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context);
    final translated = loc.translate(widget.category.nameKey);
    // If translated text is available and name is still the key, use translated text
    if (translated != widget.category.nameKey &&
        _nameController.text == widget.category.nameKey) {
      _nameController.text = translated;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static String _emojiForIcon(IconData icon) {
    if (icon == Icons.restaurant || icon == Icons.fastfood) return '🍽️';
    if (icon == Icons.local_taxi || icon == Icons.directions_bus) return '🚕';
    if (icon == Icons.shopping_bag || icon == Icons.local_grocery_store) return '🛍️';
    if (icon == Icons.health_and_safety || icon == Icons.fitness_center) return '💊';
    if (icon == Icons.local_movies || icon == Icons.music_note) return '🎬';
    if (icon == Icons.flight || icon == Icons.beach_access) return '✈️';
    if (icon == Icons.home || icon == Icons.hotel) return '🏠';
    if (icon == Icons.school) return '📚';
    if (icon == Icons.cake || icon == Icons.card_giftcard) return '🎉';
    if (icon == Icons.work) return '💼';
    if (icon == Icons.pets) return '🐕';
    if (icon == Icons.sports_basketball) return '⚽';
    if (icon == Icons.coffee) return '☕';
    if (icon == Icons.local_gas_station) return '⛽';
    return '🏷️';
  }

  void _saveCategory(AppLocalizations loc) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = loc.translate('category_name_required');
      });
      return;
    }

    final id = widget.category.id;

    // Check if new name collides with another category (excluding this one)
    final duplicate = widget.existingCategories.any(
      (c) =>
          c.id != widget.category.id &&
          (c.nameKey.toLowerCase() == name.toLowerCase() ||
              loc.translate(c.nameKey).toLowerCase() == name.toLowerCase()),
    );

    if (duplicate) {
      setState(() {
        _errorMessage = loc.translate('category_already_exists');
      });
      return;
    }

    final updatedCategory = CategoryIconItem(
      id: id,
      icon: _selectedEmoji,
      nameKey: name,
      colorHex: _selectedColorHex,
    );

    Navigator.pop(
      context,
      CategoryEditResult.updated(
        originalCategory: widget.category,
        updatedCategory: updatedCategory,
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, AppLocalizations loc) async {
    if (widget.isDefaultCategory) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('cannotDeleteDefaultSnackbar'),
          content: Text(loc.translate('cannot_delete_default_categories')),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Show Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('delete_category_title')),
        content: Text(loc.translate('delete_category_confirm_message')),
        actions: [
          TextButton(
            key: const Key('cancelDeleteCategoryButton'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            key: const Key('confirmDeleteCategoryButton'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(
        context,
        CategoryEditResult.deleted(originalCategory: widget.category),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
                Expanded(
                  child: Text(
                    loc.translate('edit_category'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
            const SizedBox(height: 12),

            // ── Category Name Field ─────────────────────────
            TextField(
              key: const Key('editCategoryNameField'),
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
                        _selectedEmoji = _emojiForIcon(icon);
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
            const SizedBox(height: 12),

            // ── Delete Button (Red warning style at bottom) ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('deleteCategoryButton'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _handleDelete(context, loc),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  loc.translate('delete'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
