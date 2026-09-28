import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  List<DocumentEntity> _deletedDocs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedDocs();
  }

  Future<void> _loadDeletedDocs() async {
    final repo = ref.read(documentRepositoryProvider);
    final docs = await repo.getRecycleBinDocuments();
    setState(() {
      _deletedDocs = docs;
      _isLoading = false;
    });
  }

  Future<void> _restoreDoc(DocumentEntity doc) async {
    AppMotion.subtleHaptic();
    final repo = ref.read(documentRepositoryProvider);
    await repo.restoreFromRecycleBin(doc);
    _loadDeletedDocs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${doc.name} restored to files'),
          backgroundColor: AppColors.success500,
        ),
      );
    }
  }

  Future<void> _deletePermanently(DocumentEntity doc) async {
    AppMotion.subtleHaptic();
    final repo = ref.read(documentRepositoryProvider);
    await repo.permanentlyDeleteDocument(doc);
    _loadDeletedDocs();
  }

  Future<void> _emptyRecycleBin() async {
    AppMotion.subtleHaptic();
    final repo = ref.read(documentRepositoryProvider);
    for (final doc in _deletedDocs) {
      await repo.permanentlyDeleteDocument(doc);
    }
    _loadDeletedDocs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recycle bin emptied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (_deletedDocs.isNotEmpty)
            TextButton(
              onPressed: _emptyRecycleBin,
              child: const Text('Empty Bin', style: TextStyle(color: AppColors.error500)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedDocs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.trash, size: 64, color: Colors.grey),
                      const SizedBox(height: AppSpacing.md),
                      Text('Recycle Bin is Empty', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Deleted documents will stay here for 30 days\nbefore permanent deletion.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _deletedDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final doc = _deletedDocs[index];
                    final format = DocumentFormat.fromExtension(doc.extension);

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: format.color.withAlpha(25),
                          child: Icon(format.icon, color: format.color, size: 20),
                        ),
                        title: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${doc.formattedSize} • In Recycle Bin'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.rotate_ccw, size: 18, color: AppColors.primary500),
                              tooltip: 'Restore',
                              onPressed: () => _restoreDoc(doc),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash, size: 18, color: AppColors.error500),
                              tooltip: 'Delete Permanently',
                              onPressed: () => _deletePermanently(doc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
