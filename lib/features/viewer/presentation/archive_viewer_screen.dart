import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Interactive viewer for Zip and compressed archives.
/// Shows internal directory hierarchy, file sizes, and allows one-tap extraction.
class ArchiveViewerScreen extends StatefulWidget {
  const ArchiveViewerScreen({super.key, required this.filePath});

  final String filePath;

  @override
  State<ArchiveViewerScreen> createState() => _ArchiveViewerScreenState();
}

class _ArchiveViewerScreenState extends State<ArchiveViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ArchiveFile> _entries = [];
  bool _isExtracting = false;
  String? _extractedDirPath;

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  Future<void> _loadArchive() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Archive file not found';
        });
        return;
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      setState(() {
        _entries = archive.files.where((f) => f.isFile).toList();
        _isLoading = false;
      });
    } catch (e, st) {
      LoggerService.error('Error reading archive', error: e, stackTrace: st);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to read archive file: ${e.toString()}';
      });
    }
  }

  Future<void> _extractAll() async {
    AppMotion.subtleHaptic();
    setState(() => _isExtracting = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final baseName = p.basenameWithoutExtension(widget.filePath);
      final outDir = Directory('${tempDir.path}/extracted_$baseName');
      if (await outDir.exists()) {
        await outDir.delete(recursive: true);
      }
      await outDir.create(recursive: true);

      final bytes = await File(widget.filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File('${outDir.path}/$filename');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory('${outDir.path}/$filename').create(recursive: true);
        }
      }

      setState(() {
        _isExtracting = false;
        _extractedDirPath = outDir.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully extracted ${_entries.length} files.'),
            backgroundColor: AppColors.success500,
          ),
        );
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction failed: $e')),
        );
      }
    }
  }

  Future<void> _openFileEntry(ArchiveFile entry) async {
    AppMotion.subtleHaptic();
    try {
      final tempDir = await getTemporaryDirectory();
      final safeName = p.basename(entry.name);
      final tempFile = File('${tempDir.path}/preview_$safeName');
      await tempFile.writeAsBytes(entry.content as List<int>);

      if (mounted) {
        DocumentOpener.open(context, tempFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open preview: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = p.basename(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (!_isLoading && _entries.isNotEmpty)
            TextButton.icon(
              onPressed: _isExtracting ? null : _extractAll,
              icon: _isExtracting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.folder_down, size: 18),
              label: Text(_isExtracting ? 'Extracting...' : 'Extract All'),
            ),
        ],
      ),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.archive, size: 64, color: AppColors.error500),
              const SizedBox(height: AppSpacing.md),
              Text('Archive Error', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DocoraButton(
                label: 'Retry',
                icon: LucideIcons.refresh_cw,
                onPressed: _loadArchive,
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Text('Archive is empty', style: theme.textTheme.bodyLarge),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: colorScheme.surfaceContainerHighest.withAlpha(80),
          child: Row(
            children: [
              const Icon(LucideIcons.file_archive, size: 18, color: AppColors.fileArchive),
              const SizedBox(width: 8),
              Text(
                '${_entries.length} files inside archive',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = _entries[index];
              final ext = p.extension(entry.name);
              final format = DocumentFormat.fromExtension(ext);
              final size = entry.size;
              String sizeStr = '$size B';
              if (size > 1024 * 1024) {
                sizeStr = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
              } else if (size > 1024) {
                sizeStr = '${(size / 1024).toStringAsFixed(1)} KB';
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: format.color.withAlpha(25),
                  child: Icon(format.icon, color: format.color, size: 20),
                ),
                title: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(sizeStr),
                trailing: const Icon(LucideIcons.chevron_right, size: 16),
                onTap: () => _openFileEntry(entry),
              );
            },
          ),
        ),
      ],
    );
  }
}
