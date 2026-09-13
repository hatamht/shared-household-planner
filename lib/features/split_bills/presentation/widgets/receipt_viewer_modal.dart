import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class ReceiptViewerModal extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String? title;
  final void Function(int index)? onDelete;

  const ReceiptViewerModal({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.title,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> imagePaths,
    int initialIndex = 0,
    String? title,
    void Function(int index)? onDelete,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => ReceiptViewerModal(
        imagePaths: imagePaths,
        initialIndex: initialIndex,
        title: title,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ReceiptViewerModal> createState() => _ReceiptViewerModalState();
}

class _ReceiptViewerModalState extends State<ReceiptViewerModal> {
  late PageController _pageController;
  late int _currentIndex;
  late List<String> _paths;

  @override
  void initState() {
    super.initState();
    _paths = List.from(widget.imagePaths);
    _currentIndex = widget.initialIndex.clamp(0, _paths.isEmpty ? 0 : _paths.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < _paths.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _deleteCurrent() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('delete_receipt')),
        content: Text(loc.translate('delete_receipt_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            key: const Key('confirmDeleteReceiptButton'),
            onPressed: () {
              Navigator.of(ctx).pop();
              final deletedIdx = _currentIndex;
              widget.onDelete?.call(deletedIdx);
              setState(() {
                _paths.removeAt(deletedIdx);
                if (_paths.isEmpty) {
                  Navigator.of(context).pop();
                } else {
                  if (_currentIndex >= _paths.length) {
                    _currentIndex = _paths.length - 1;
                  }
                  _pageController.jumpToPage(_currentIndex);
                }
              });
            },
            child: Text(
              loc.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_paths.isEmpty) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.translate('no_receipt')),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('receiptViewerCloseButton'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.translate('close')),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      key: const Key('receiptViewerModal'),
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title ?? loc.translate('receipt_images'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_paths.length > 1) ...[
                          const SizedBox(height: 2),
                          Text(
                            key: const Key('receiptGalleryPageIndicator'),
                            '${_currentIndex + 1} / ${_paths.length}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      key: const Key('deleteReceiptButton'),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: loc.translate('delete_receipt'),
                      onPressed: _deleteCurrent,
                    ),
                  IconButton(
                    key: const Key('receiptViewerCloseButton'),
                    icon: const Icon(Icons.close),
                    tooltip: loc.translate('close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Image Gallery PageView with Zoom
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    key: const Key('receiptGalleryPageView'),
                    controller: _pageController,
                    itemCount: _paths.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final path = _paths[index];
                      final file = File(path);
                      final fileExists = file.existsSync();

                      return Container(
                        key: Key('receiptGalleryPage_$index'),
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: InteractiveViewer(
                            panEnabled: true,
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.8,
                            maxScale: 4.0,
                            child: fileExists
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      file,
                                      key: Key('receiptViewerImage_$index'),
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Container(
                                    key: Key('receiptViewerPlaceholder_$index'),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.white10 : Colors.black12,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          size: 80,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          loc.translate('receipt_preview'),
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          path.split('/').last,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.grey),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Previous navigation button
                  if (_paths.length > 1 && _currentIndex > 0)
                    Positioned(
                      left: 8,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          key: const Key('receiptPrevButton'),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 18, color: Colors.white),
                          onPressed: _goToPrevious,
                          tooltip: loc.translate('previous'),
                        ),
                      ),
                    ),

                  // Next navigation button
                  if (_paths.length > 1 && _currentIndex < _paths.length - 1)
                    Positioned(
                      right: 8,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          key: const Key('receiptNextButton'),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.white),
                          onPressed: _goToNext,
                          tooltip: loc.translate('next_page'),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Thumbnail Strip for Multi-Image
            if (_paths.length > 1)
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141414) : Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _paths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final isSelected = idx == _currentIndex;
                    final path = _paths[idx];
                    final file = File(path);
                    return GestureDetector(
                      key: Key('receiptGalleryStripItem_$idx'),
                      onTap: () {
                        _pageController.animateToPage(
                          idx,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: file.existsSync()
                              ? Image.file(file, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image, size: 20, color: Colors.grey),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
