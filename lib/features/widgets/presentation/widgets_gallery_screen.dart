import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/router/app_routes.dart';
import 'package:docora/features/widgets/domain/models/docora_widget_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

class WidgetsGalleryScreen extends StatefulWidget {
  const WidgetsGalleryScreen({super.key});

  @override
  State<WidgetsGalleryScreen> createState() => _WidgetsGalleryScreenState();
}

class _WidgetsGalleryScreenState extends State<WidgetsGalleryScreen> {
  static const _channel = MethodChannel('com.docora.app/file_intent');
  WidgetCategory _selectedCategory = WidgetCategory.all;
  bool _phoneMockupMode = false;
  int _selectedMockupIndex = 0;

  List<DocoraWidgetModel> get _filteredWidgets {
    if (_selectedCategory == WidgetCategory.all) {
      return DocoraWidgetModel.availableWidgets;
    }
    return DocoraWidgetModel.availableWidgets
        .where((w) => w.category == _selectedCategory)
        .toList();
  }

  Future<void> _pinWidgetToHomeScreen(DocoraWidgetModel widget) async {
    HapticFeedback.mediumImpact();
    try {
      final success = await _channel.invokeMethod<bool>('pinWidget', {
        'widgetId': widget.id,
      });

      if (!mounted) return;
      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(LucideIcons.circle_check, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${widget.name} request sent! Confirm on your home screen.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        _showManualPinGuideDialog(widget);
      }
    } catch (_) {
      if (mounted) {
        _showManualPinGuideDialog(widget);
      }
    }
  }

  void _showManualPinGuideDialog(DocoraWidgetModel widget) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181824) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.layout_grid, color: widget.accentColor, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add ${widget.name}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Grid Size: ${widget.gridSize}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildStepItem(
                ctx,
                stepNumber: '1',
                title: 'Go to your phone Home Screen',
                description: 'Press your phone\'s Home button to exit to your home launcher.',
              ),
              _buildStepItem(
                ctx,
                stepNumber: '2',
                title: 'Long-press any empty space',
                description: 'Touch and hold on any blank wallpaper area until the menu appears.',
              ),
              _buildStepItem(
                ctx,
                stepNumber: '3',
                title: 'Tap "Widgets"',
                description: 'Select the Widgets icon from the bottom customization bar.',
              ),
              _buildStepItem(
                ctx,
                stepNumber: '4',
                title: 'Find "Docora" & drag "${widget.name}"',
                description: 'Drag the ${widget.gridSize} widget onto your screen. You\'re done!',
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepItem(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F17) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Home Screen Widgets',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _phoneMockupMode ? 'List View' : 'Phone Screen Preview',
            icon: Icon(_phoneMockupMode ? LucideIcons.layout_list : LucideIcons.smartphone),
            onPressed: () {
              setState(() {
                _phoneMockupMode = !_phoneMockupMode;
              });
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _phoneMockupMode ? _buildPhoneMockupView() : _buildCatalogListView(),
    );
  }

  Widget _buildCatalogListView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Intro Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
                  : [const Color(0xFFEEF2FF), const Color(0xFFFDF4FF)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(20) : Colors.indigo.withAlpha(30),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.layout_template, color: Color(0xFF6366F1), size: 30),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supercharge Your Desktop',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add fast 1-tap widgets to scan, resume reading, launch tools, or protect your vault right from your home screen.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: WidgetCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat.label),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  backgroundColor: isDark ? const Color(0xFF1C1B2A) : Colors.white,
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Widgets Cards
        ..._filteredWidgets.map((widget) => _buildWidgetDetailCard(widget)),
      ],
    );
  }

  Widget _buildWidgetDetailCard(DocoraWidgetModel widget) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161524) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Subtitle, Size Badge
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.gridSize,
                              style: TextStyle(
                                color: widget.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.category.label,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Visual Preview of the Widget
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0E1A) : const Color(0xFFF1F5F9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.eye, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Live Widget Preview (${widget.gridSize})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildLiveWidgetGraphic(widget),
              ],
            ),
          ),

          // Capabilities & Work details ("kya work karega")
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What this widget does (Features):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...widget.capabilities.map((cap) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(cap.icon, size: 16, color: widget.accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                                children: [
                                  TextSpan(
                                    text: '${cap.title}: ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: cap.description),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: AppSpacing.sm),
                // Actions: Pin to Home Screen & Test Feature
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(LucideIcons.circle_plus, size: 18),
                        label: const Text('Add to Home Screen', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _pinWidgetToHomeScreen(widget),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      icon: const Icon(LucideIcons.external_link, size: 18),
                      label: const Text('Launch'),
                      onPressed: () {
                        context.push(widget.targetRoute);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds true-to-life interactive widget preview based on its ID
  Widget _buildLiveWidgetGraphic(DocoraWidgetModel widget) {
    switch (widget.id) {
      case 'quick_scanner':
        return _buildScannerWidgetPreview();
      case 'recent_reading':
        return _buildRecentReadingWidgetPreview();
      case 'tools_hub':
        return _buildToolsHubWidgetPreview();
      case 'private_vault':
        return _buildVaultWidgetPreview();
      case 'reading_tracker':
        return _buildReadingTrackerWidgetPreview();
      case 'audio_reader':
        return _buildAudioReaderWidgetPreview();
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. Scanner Widget (4x1)
  Widget _buildScannerWidgetPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(25)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.scan_line, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Instant Doc Scanner',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Tap camera to digitize notes & receipts',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.camera, color: Colors.white, size: 22),
            tooltip: 'Launch Camera',
            onPressed: () => context.push(AppRoutes.scanner),
          ),
          IconButton(
            icon: const Icon(LucideIcons.image, color: Colors.white70, size: 20),
            tooltip: 'Import from Gallery',
            onPressed: () => context.push(AppRoutes.scanner),
          ),
        ],
      ),
    );
  }

  // 2. Recent Reading Carousel (4x2)
  Widget _buildRecentReadingWidgetPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(25)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0EA5E9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'CONTINUE READING',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              const Text(
                '78% completed',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(LucideIcons.presentation, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recombinant DNA Technology',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Slide 4 of 6 • Atiya Zarreen.pptx',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.78,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF0EA5E9)),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => context.push(AppRoutes.home),
                child: const Text('Resume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Power Tools Hub (4x2)
  Widget _buildToolsHubWidgetPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wrench, color: Color(0xFFA855F7), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Docora Power Tools Hub',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('4x2 Desktop', style: TextStyle(color: Color(0xFFD8B4FE), fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildToolMiniButton(
                icon: LucideIcons.images,
                label: 'Image to PDF',
                color: const Color(0xFFEC4899),
                onTap: () => context.push(AppRoutes.tools),
              ),
              const SizedBox(width: 8),
              _buildToolMiniButton(
                icon: LucideIcons.file_plus,
                label: 'Merge PDF',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push(AppRoutes.tools),
              ),
              const SizedBox(width: 8),
              _buildToolMiniButton(
                icon: LucideIcons.shield_check,
                label: 'Watermark',
                color: const Color(0xFF3B82F6),
                onTap: () => context.push(AppRoutes.tools),
              ),
              const SizedBox(width: 8),
              _buildToolMiniButton(
                icon: LucideIcons.archive,
                label: 'Compress',
                color: const Color(0xFF10B981),
                onTap: () => context.push(AppRoutes.tools),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolMiniButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Private Vault (2x2)
  Widget _buildVaultWidgetPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF230D14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shield_alert, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Docora Vault Status',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'AES-256 Hardware Encrypted',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.lock, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text('LOCKED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('4 Protected Docs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('IDs, Contracts & Passes', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(LucideIcons.shield_check, size: 16),
                label: const Text('Unlock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => context.push(AppRoutes.vault),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Reading Tracker (4x1)
  Widget _buildReadingTrackerWidgetPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF291B07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.flame, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🔥 7-Day Reading Streak',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '32 of 45 mins read today • Keep it up!',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '71%',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Audio Reader / TTS Widget (4x2)
  Widget _buildAudioReaderWidgetPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF062D20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.volume_2, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Text(
                'TTS Document Audio Reader',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('1.25x Speed', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Speaking: Slide 2 • Introduction to Biotechnology',
            style: TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.rotate_ccw, color: Colors.white70, size: 20),
                tooltip: 'Rewind 15s',
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.play, color: Colors.white, size: 22),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(LucideIcons.rotate_cw, color: Colors.white70, size: 20),
                tooltip: 'Forward 15s',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Phone Home Screen Simulator ("phir screen pr kaisa dikhega")
  Widget _buildPhoneMockupView() {
    final activeWidget = DocoraWidgetModel.availableWidgets[_selectedMockupIndex];

    return Column(
      children: [
        // Widget Switcher Tabs
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: DocoraWidgetModel.availableWidgets.length,
            itemBuilder: (ctx, idx) {
              final w = DocoraWidgetModel.availableWidgets[idx];
              final isSelected = idx == _selectedMockupIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('${w.name} (${w.gridSize})'),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedMockupIndex = idx;
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),

        // Smartphone Frame with live wallpaper and pinned widget
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 18,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: const Color(0xFF334155), width: 6),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 10)),
                  ],
                  // Android Wallpaper
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E1B4B),
                      Color(0xFF311042),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      // Status Bar
                      Positioned(
                        top: 8,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '9:41',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            // Camera Notch pill
                            Container(
                              width: 60,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(LucideIcons.wifi, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Icon(LucideIcons.battery_medium, color: Colors.white, size: 14),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Clock & Date on Phone Home Screen
                      const Positioned(
                        top: 48,
                        left: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '09:41',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'Wednesday, October 24',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // The Pinned Widget placed on the Desktop
                      Positioned(
                        top: 155,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLiveWidgetGraphic(activeWidget),
                          ],
                        ),
                      ),

                      // Simulated Phone App Icons Dock at bottom
                      Positioned(
                        bottom: 24,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMockAppIcon(LucideIcons.phone, Colors.green),
                            _buildMockAppIcon(LucideIcons.message_circle, Colors.blue),
                            _buildMockAppIcon(LucideIcons.globe, Colors.deepPurple),
                            _buildDocoraAppIcon(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: activeWidget.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(LucideIcons.circle_plus, size: 20),
              label: Text('Pin "${activeWidget.name}" to Home Screen',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _pinWidgetToHomeScreen(activeWidget),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockAppIcon(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildDocoraAppIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage('assets/icons/app_icon.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
