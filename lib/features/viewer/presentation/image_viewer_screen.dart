import 'dart:io';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

/// Full-featured, immersive image viewer supporting pinch-to-zoom, rotation,
/// image details, and one-tap export/convert.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.filePath});

  final String filePath;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  int _rotationQuarterTurns = 0;
  bool _showControls = true;
  late final File _file;

  @override
  void initState() {
    super.initState();
    _file = File(widget.filePath);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _rotate() {
    AppMotion.subtleHaptic();
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _share() {
    AppMotion.subtleHaptic();
    Share.shareXFiles([XFile(widget.filePath)], text: p.basename(widget.filePath));
  }

  void _showDetails() {
    AppMotion.subtleHaptic();
    final name = p.basename(widget.filePath);
    final ext = p.extension(widget.filePath).toUpperCase();
    int sizeBytes = 0;
    DateTime? modified;

    try {
      if (_file.existsSync()) {
        final stat = _file.statSync();
        sizeBytes = stat.size;
        modified = stat.modified;
      }
    } catch (_) {}

    String formattedSize = '$sizeBytes B';
    if (sizeBytes > 1024 * 1024) {
      formattedSize = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (sizeBytes > 1024) {
      formattedSize = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }

    DocoraBottomSheet.show<void>(
      context: context,
      title: 'Image Information',
      subtitle: name,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(label: 'Format', value: ext.replaceAll('.', '')),
            _InfoRow(label: 'File Size', value: formattedSize),
            if (modified != null)
              _InfoRow(
                label: 'Modified',
                value: '${modified.day}/${modified.month}/${modified.year} ${modified.hour}:${modified.minute.toString().padLeft(2, '0')}',
              ),
            _InfoRow(label: 'Location', value: widget.filePath, isPath: true),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = p.basename(widget.filePath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Pinch-to-zoom Image
          GestureDetector(
            onTap: _toggleControls,
            child: Center(
              child: RotatedBox(
                quarterTurns: _rotationQuarterTurns,
                child: PhotoView(
                  imageProvider: FileImage(_file),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4.0,
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.filePath),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary500),
                  ),
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.image_off, size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to render image',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.filePath,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top App Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                bottom: 8,
                left: 8,
                right: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(200),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.info, color: Colors.white),
                    tooltip: 'Details',
                    onPressed: _showDetails,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.share_2, color: Colors.white),
                    tooltip: 'Share',
                    onPressed: _share,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 12,
                top: 12,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(220),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: LucideIcons.rotate_cw,
                    label: 'Rotate',
                    onTap: _rotate,
                  ),
                  _ActionButton(
                    icon: LucideIcons.share_2,
                    label: 'Share',
                    onTap: _share,
                  ),
                  _ActionButton(
                    icon: LucideIcons.info,
                    label: 'Details',
                    onTap: _showDetails,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isPath = false,
  });

  final String label;
  final String value;
  final bool isPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isPath ? 12 : 14,
                fontFamily: isPath ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
