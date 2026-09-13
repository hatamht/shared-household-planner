import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../split_bills/domain/entities/category_icon.dart';
import '../../../split_bills/presentation/pages/add_bill_screen.dart';
import '../../domain/entities/bill_template.dart';
import '../bloc/bill_templates_bloc.dart';

class BillTemplatesScreen extends StatefulWidget {
  final String? projectId;
  final void Function(BillTemplate)? onSelectTemplate;

  const BillTemplatesScreen({
    super.key,
    this.projectId,
    this.onSelectTemplate,
  });

  @override
  State<BillTemplatesScreen> createState() => _BillTemplatesScreenState();
}

class _BillTemplatesScreenState extends State<BillTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<BillTemplatesBloc>().add(LoadTemplatesEvent(projectId: widget.projectId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showTemplateDialog({BillTemplate? templateToEdit}) {
    final isEditing = templateToEdit != null;
    final titleController = TextEditingController(text: templateToEdit?.title ?? '');
    final amountController = TextEditingController(
      text: templateToEdit != null && templateToEdit.amount > 0
          ? templateToEdit.amount.toStringAsFixed(0)
          : '',
    );
    final paidByController = TextEditingController(text: templateToEdit?.paidBy ?? '');
    final participantsController = TextEditingController(
      text: templateToEdit?.participants.join(', ') ?? '',
    );

    String selectedCategory = templateToEdit?.category ?? 'utilities';
    String selectedCurrency = templateToEdit?.currency ?? 'VND';
    String selectedSplitMode = templateToEdit?.splitMode ?? 'equal';
    bool isFavorite = templateToEdit?.isFavorite ?? false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final loc = AppLocalizations.of(context);
            return AlertDialog(
              key: const Key('templateFormDialog'),
              title: Text(
                key: const Key('templateDialogTitle'),
                isEditing
                    ? loc.translate('edit_template')
                    : loc.translate('create_template'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('templateTitleInput'),
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: loc.translate('template_name'),
                        hintText: 'e.g. Electric Bill, Rent',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('templateAmountInput'),
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.translate('amount'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('templateCategoryDropdown'),
                      value: defaultCategoryIcons.any((c) => c.id == selectedCategory)
                          ? selectedCategory
                          : defaultCategoryIcons.first.id,
                      decoration: InputDecoration(labelText: loc.translate('category')),
                      items: defaultCategoryIcons.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Text(c.icon),
                              const SizedBox(width: 8),
                              Text(loc.translate(c.nameKey)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('templateCurrencyDropdown'),
                      value: selectedCurrency,
                      decoration: InputDecoration(labelText: loc.translate('currency')),
                      items: const [
                        DropdownMenuItem(value: 'VND', child: Text('VND (₫)')),
                        DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                        DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCurrency = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('templatePaidByInput'),
                      controller: paidByController,
                      decoration: InputDecoration(
                        labelText: loc.translate('payer'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('templateParticipantsInput'),
                      controller: participantsController,
                      decoration: InputDecoration(
                        labelText: loc.translate('participants'),
                        hintText: 'e.g. Alice, Bob, Charlie',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      key: const Key('templateFavoriteSwitch'),
                      title: Text(loc.translate('mark_favorite')),
                      value: isFavorite,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() => isFavorite = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('cancelTemplateDialogButton'),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(loc.translate('cancel')),
                ),
                ElevatedButton(
                  key: const Key('saveTemplateDialogButton'),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    final participants = participantsController.text
                        .split(',')
                        .map((p) => p.trim())
                        .where((p) => p.isNotEmpty)
                        .toList();

                    final catMatch = defaultCategoryIcons.where((c) => c.id == selectedCategory);
                    final icon = catMatch.isNotEmpty ? catMatch.first.icon : '📝';
                    final color = catMatch.isNotEmpty ? catMatch.first.colorHex : '#9E9E9E';

                    if (isEditing) {
                      final updated = templateToEdit.copyWith(
                        title: title,
                        amount: amount,
                        category: selectedCategory,
                        categoryIcon: icon,
                        categoryColor: color,
                        currency: selectedCurrency,
                        paidBy: paidByController.text.trim().isNotEmpty
                            ? paidByController.text.trim()
                            : null,
                        participants: participants,
                        splitMode: selectedSplitMode,
                        isFavorite: isFavorite,
                      );
                      context.read<BillTemplatesBloc>().add(UpdateTemplateEvent(updated));
                    } else {
                      final newTemplate = BillTemplate(
                        id: const Uuid().v4(),
                        title: title,
                        amount: amount,
                        category: selectedCategory,
                        categoryIcon: icon,
                        categoryColor: color,
                        currency: selectedCurrency,
                        paidBy: paidByController.text.trim().isNotEmpty
                            ? paidByController.text.trim()
                            : null,
                        participants: participants,
                        splitMode: selectedSplitMode,
                        projectId: widget.projectId,
                        isFavorite: isFavorite,
                        createdAt: DateTime.now(),
                      );
                      context.read<BillTemplatesBloc>().add(CreateTemplateEvent(newTemplate));
                    }
                    Navigator.of(dialogCtx).pop();
                  },
                  child: Text(loc.translate('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BillTemplate template) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          key: const Key('confirmDeleteTemplateDialog'),
          title: Text(loc.translate('delete_template')),
          content: Text(
            loc.translate('delete_template_confirm').replaceAll('{title}', template.title),
          ),
          actions: [
            TextButton(
              key: const Key('cancelDeleteButton'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              key: const Key('confirmDeleteButton'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                context.read<BillTemplatesBloc>().add(DeleteTemplateEvent(template.id));
                Navigator.of(dialogCtx).pop();
              },
              child: Text(loc.translate('delete')),
            ),
          ],
        );
      },
    );
  }

  void _useTemplate(BillTemplate template) {
    // Increment usage record
    context.read<BillTemplatesBloc>().add(RecordTemplateUsageEvent(template.id));

    if (widget.onSelectTemplate != null) {
      widget.onSelectTemplate!(template);
      Navigator.of(context).pop();
    } else {
      // Open AddBillScreen pre-filled from template
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddBillScreen(
            template: template,
            projectId: template.projectId ?? widget.projectId,
          ),
        ),
      );
    }
  }

  List<BillTemplate> _filterTemplates(List<BillTemplate> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          (t.paidBy?.toLowerCase().contains(q) ?? false) ||
          t.participants.any((p) => p.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: const Key('billTemplatesScreen'),
      appBar: AppBar(
        title: Text(loc.translate('bill_templates')),
        actions: [
          IconButton(
            key: const Key('createTemplateButton'),
            icon: const Icon(Icons.add),
            tooltip: loc.translate('create_template'),
            onPressed: () => _showTemplateDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(key: const Key('allTemplatesTab'), text: loc.translate('all')),
            Tab(
              key: const Key('favoriteTemplatesTab'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(loc.translate('favorite_templates')),
                ],
              ),
            ),
            Tab(
              key: const Key('suggestedTemplatesTab'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(loc.translate('suggested_templates')),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              key: const Key('searchTemplatesField'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: loc.translate('search_templates'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<BillTemplatesBloc, BillTemplatesState>(
              builder: (context, state) {
                if (state is BillTemplatesLoading) {
                  return const Center(
                    key: Key('templatesLoadingIndicator'),
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is BillTemplatesError) {
                  return Center(
                    child: Text(state.message, style: const TextStyle(color: Colors.red)),
                  );
                }

                if (state is BillTemplatesLoaded) {
                  final allTemplates = _filterTemplates(state.templates);
                  final favTemplates = _filterTemplates(state.favorites);
                  final suggestedTemplates = _filterTemplates(state.suggested);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTemplateList(allTemplates, loc, isDark, emptyKey: 'no_templates_yet'),
                      _buildTemplateList(favTemplates, loc, isDark, emptyKey: 'no_favorite_templates'),
                      _buildTemplateList(suggestedTemplates, loc, isDark, emptyKey: 'no_suggested_templates'),
                    ],
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('createTemplateFAB'),
        tooltip: loc.translate('create_template'),
        child: const Icon(Icons.add),
        onPressed: () => _showTemplateDialog(),
      ),
    );
  }

  Widget _buildTemplateList(
    List<BillTemplate> templates,
    AppLocalizations loc,
    bool isDark, {
    required String emptyKey,
  }) {
    if (templates.isEmpty) {
      return Center(
        key: Key('emptyTemplates_$emptyKey'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              loc.translate(emptyKey),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: Key('templatesListView_$emptyKey'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final currencySymbol = currencySymbols[template.currency] ?? template.currency;

        return Card(
          key: Key('templateCard_${template.id}'),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category Icon Badge
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  child: Text(
                    template.categoryIcon ?? '📝',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              template.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (template.isFavorite) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${template.amount.toStringAsFixed(0)} $currencySymbol • ${loc.translate('category_${template.category}')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (template.participants.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${template.participants.length} ${loc.translate('participants')}: ${template.participants.join(', ')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (template.usageCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          loc.translate('used_count').replaceAll('{count}', '${template.usageCount}'),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite Toggle
                    IconButton(
                      key: Key('toggleFavorite_${template.id}'),
                      icon: Icon(
                        template.isFavorite ? Icons.star : Icons.star_border,
                        color: template.isFavorite ? Colors.amber : Colors.grey,
                      ),
                      tooltip: template.isFavorite
                          ? loc.translate('unmark_favorite')
                          : loc.translate('mark_favorite'),
                      onPressed: () {
                        context
                            .read<BillTemplatesBloc>()
                            .add(ToggleFavoriteTemplateEvent(template.id));
                      },
                    ),

                    // Edit button
                    IconButton(
                      key: Key('editTemplate_${template.id}'),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: loc.translate('edit'),
                      onPressed: () => _showTemplateDialog(templateToEdit: template),
                    ),

                    // Delete button
                    IconButton(
                      key: Key('deleteTemplate_${template.id}'),
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      tooltip: loc.translate('delete'),
                      onPressed: () => _confirmDelete(template),
                    ),

                    const SizedBox(width: 4),

                    // Use button
                    ElevatedButton(
                      key: Key('useTemplate_${template.id}'),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _useTemplate(template),
                      child: Text(loc.translate('use_template')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
