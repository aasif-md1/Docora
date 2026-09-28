import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:docora/core/router/app_routes.dart';

enum WidgetCategory {
  all('All'),
  productivity('Productivity'),
  reading('Reading'),
  security('Security'),
  media('Media & Audio');

  const WidgetCategory(this.label);
  final String label;
}

class WidgetFeatureCapability {
  const WidgetFeatureCapability({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class DocoraWidgetModel {
  const DocoraWidgetModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.gridSize,
    required this.category,
    required this.description,
    required this.capabilities,
    required this.accentColor,
    required this.targetRoute,
  });

  final String id;
  final String name;
  final String subtitle;
  final String gridSize; // e.g. "4x2", "4x1", "2x2"
  final WidgetCategory category;
  final String description;
  final List<WidgetFeatureCapability> capabilities;
  final Color accentColor;
  final String targetRoute;

  static const List<DocoraWidgetModel> availableWidgets = [
    DocoraWidgetModel(
      id: 'quick_scanner',
      name: 'Instant Document Scanner',
      subtitle: 'Camera scan, OCR & batch digitizer',
      gridSize: '4x1',
      category: WidgetCategory.productivity,
      description:
          'Place this widget on your home screen to instantly capture physical receipts, invoices, IDs, and book pages without ever having to unlock and search for the app first.',
      capabilities: [
        WidgetFeatureCapability(
          title: '1-Tap Camera Scan',
          description: 'Opens camera instantly with auto-edge detection and perspective warping.',
          icon: LucideIcons.camera,
        ),
        WidgetFeatureCapability(
          title: 'Import & Digitize',
          description: 'Quick-select receipts or photos from your gallery to convert to crisp PDF.',
          icon: LucideIcons.image,
        ),
        WidgetFeatureCapability(
          title: 'Batch Mode Toggle',
          description: 'Digitize entire books or multi-page contracts into a single indexed PDF.',
          icon: LucideIcons.copy,
        ),
      ],
      accentColor: Color(0xFF6366F1),
      targetRoute: AppRoutes.scanner,
    ),
    DocoraWidgetModel(
      id: 'recent_reading',
      name: 'Recent Documents & Reading Carousel',
      subtitle: 'Live progress, recent files & 1-tap resume',
      gridSize: '4x2',
      category: WidgetCategory.reading,
      description:
          'Track your ongoing reading progress right on your phone home screen. Shows current book/presentation thumbnails, read percentages, and lets you jump back to your exact page in 1 tap.',
      capabilities: [
        WidgetFeatureCapability(
          title: '1-Tap Resume Reading',
          description: 'Directly opens your last active document at the exact page you paused at.',
          icon: LucideIcons.book_open,
        ),
        WidgetFeatureCapability(
          title: 'Live Reading Progress',
          description: 'Visual progress bar showing completed percentage and remaining pages.',
          icon: LucideIcons.layers,
        ),
        WidgetFeatureCapability(
          title: 'Recent Files Quick Access',
          description: 'Scroll through your 5 most recently viewed presentations, PDFs, and docs.',
          icon: LucideIcons.clock,
        ),
      ],
      accentColor: Color(0xFF0EA5E9),
      targetRoute: AppRoutes.home,
    ),
    DocoraWidgetModel(
      id: 'tools_hub',
      name: 'Docora Power Tools Hub',
      subtitle: 'Image to PDF, Merge, Watermark & Compress',
      gridSize: '4x2',
      category: WidgetCategory.productivity,
      description:
          'Turn your home screen into a high-powered document workstation with instant 1-tap shortcuts to Image to PDF with crop/rotate, PDF merge, digital signing, and file compression.',
      capabilities: [
        WidgetFeatureCapability(
          title: 'Image to PDF Studio',
          description: 'Select multiple photos, crop, rotate 90°, and compile high-resolution PDF.',
          icon: LucideIcons.images,
        ),
        WidgetFeatureCapability(
          title: 'PDF Merger & Splitter',
          description: 'Combine multiple invoices or slides together seamlessly.',
          icon: LucideIcons.file_plus,
        ),
        WidgetFeatureCapability(
          title: 'Watermark & Sign',
          description: 'Stamp confidentiality badges or your digital signature in seconds.',
          icon: LucideIcons.shield_check,
        ),
        WidgetFeatureCapability(
          title: 'Lossless PDF Compressor',
          description: 'Shrink bulky documents for quick email and WhatsApp sharing.',
          icon: LucideIcons.archive,
        ),
      ],
      accentColor: Color(0xFF8B5CF6),
      targetRoute: AppRoutes.tools,
    ),
    DocoraWidgetModel(
      id: 'private_vault',
      name: 'Private Vault Quick-Lock',
      subtitle: 'Biometric status & emergency lock shield',
      gridSize: '2x2',
      category: WidgetCategory.security,
      description:
          'Keep your sensitive identity docs, contracts, and financial statements safe. Shows real-time biometric encryption status and gives instant 1-tap emergency lock protection.',
      capabilities: [
        WidgetFeatureCapability(
          title: 'Biometric Access',
          description: 'Authenticate with fingerprint or face unlock to access protected files.',
          icon: LucideIcons.shield_check,
        ),
        WidgetFeatureCapability(
          title: 'Emergency Lock Shield',
          description: 'Instantly lock all open documents and purge memory in a single tap.',
          icon: LucideIcons.lock,
        ),
        WidgetFeatureCapability(
          title: 'Encrypted Counter',
          description: 'Monitors total protected documents stored inside your hardware keystore.',
          icon: LucideIcons.key_round,
        ),
      ],
      accentColor: Color(0xFFEF4444),
      targetRoute: AppRoutes.vault,
    ),
    DocoraWidgetModel(
      id: 'reading_tracker',
      name: 'Daily Reading Goal & Streak',
      subtitle: 'Track minutes, streak flames & page stats',
      gridSize: '4x1',
      category: WidgetCategory.reading,
      description:
          'Build a powerful daily reading habit. Displays today\'s reading time, daily goal completion rings, active streak flames, and motivational quotes on your desktop.',
      capabilities: [
        WidgetFeatureCapability(
          title: 'Daily Goal Rings',
          description: 'Tracks today\'s minutes spent reading against your daily 30-min goal.',
          icon: LucideIcons.target,
        ),
        WidgetFeatureCapability(
          title: 'Reading Streak Flame',
          description: 'Shows consecutive active days to keep your learning momentum high.',
          icon: LucideIcons.flame,
        ),
        WidgetFeatureCapability(
          title: 'Pages Completed',
          description: 'Tracks total pages digested across presentations, books, and articles.',
          icon: LucideIcons.award,
        ),
      ],
      accentColor: Color(0xFFF59E0B),
      targetRoute: AppRoutes.home,
    ),
    DocoraWidgetModel(
      id: 'audio_reader',
      name: 'TTS Audio Reader Mini-Player',
      subtitle: 'Listen to slides & PDFs hands-free',
      gridSize: '4x2',
      category: WidgetCategory.media,
      description:
          'Control hands-free Text-to-Speech narration right from your home screen. Play, pause, skip paragraphs, and adjust narration speed while multitasking or commuting.',
      capabilities: [
        WidgetFeatureCapability(
          title: 'Play / Pause Controls',
          description: 'Instant playback toggle for the document currently being read aloud.',
          icon: LucideIcons.play,
        ),
        WidgetFeatureCapability(
          title: 'Speed Controller (1x - 2x)',
          description: 'Toggle speech speed between normal, 1.25x, 1.5x, and 2.0x speeds.',
          icon: LucideIcons.gauge,
        ),
        WidgetFeatureCapability(
          title: '15s Seek & Paragraph Jump',
          description: 'Quickly rewind or skip forward through lecture slides and dense pages.',
          icon: LucideIcons.fast_forward,
        ),
      ],
      accentColor: Color(0xFF10B981),
      targetRoute: AppRoutes.home,
    ),
  ];
}
