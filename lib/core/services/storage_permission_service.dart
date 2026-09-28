import 'dart:io';

import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_bottom_sheet.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:permission_handler/permission_handler.dart';

/// Storage permission status abstraction
enum StoragePermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

/// Service to check and request Android storage access permissions.
/// Follows scoped storage guidelines and handles Android 11+ All Files Access.
class StoragePermissionService {
  const StoragePermissionService();

  /// Check current storage permission state
  Future<StoragePermissionState> checkPermission() async {
    if (!Platform.isAndroid) {
      return StoragePermissionState.granted;
    }

    try {
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        return StoragePermissionState.granted;
      }

      // Check legacy storage permission for Android 10 and below
      final legacyStatus = await Permission.storage.status;
      if (legacyStatus.isGranted) {
        return StoragePermissionState.granted;
      }

      if (status.isPermanentlyDenied || legacyStatus.isPermanentlyDenied) {
        return StoragePermissionState.permanentlyDenied;
      }

      return StoragePermissionState.denied;
    } on Object catch (e, st) {
      LoggerService.error('Error checking storage permission', error: e, stackTrace: st);
      return StoragePermissionState.denied;
    }
  }

  /// Request storage access permission
  Future<StoragePermissionState> requestPermission() async {
    if (!Platform.isAndroid) {
      return StoragePermissionState.granted;
    }

    try {
      // Android 11+ (API 30+) requires MANAGE_EXTERNAL_STORAGE for document manager
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return StoragePermissionState.granted;
      }

      // Fallback for Android 10 and below
      final legacyStatus = await Permission.storage.request();
      if (legacyStatus.isGranted) {
        return StoragePermissionState.granted;
      }

      if (status.isPermanentlyDenied || legacyStatus.isPermanentlyDenied) {
        return StoragePermissionState.permanentlyDenied;
      }

      return StoragePermissionState.denied;
    } on Object catch (e, st) {
      LoggerService.error('Error requesting storage permission', error: e, stackTrace: st);
      return StoragePermissionState.denied;
    }
  }

  /// Open application system settings
  Future<bool> openSettings() => openAppSettings();

  /// Show a standardized bottom sheet explaining why Docora requires storage access.
  static Future<bool> showRationaleSheet(BuildContext context) async {
    AppMotion.subtleHaptic();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await DocoraBottomSheet.show<bool>(
      context: context,
      title: 'Storage Access',
      subtitle: 'Required for offline document discovery',
      showCloseButton: true,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon visual
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withAlpha(25),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(50),
                ),
              ),
              child: Icon(
                LucideIcons.folder_open,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Offline Document Management',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            'Docora needs permission to read documents on your device so you can view, edit, and organize PDF, Word, Excel, and office files without an internet connection.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Privacy note
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.shield_check,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '100% Private. Docora has no internet permission. Your files never leave this device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action buttons
          DocoraButton(
            label: 'Allow Storage Access',
            icon: LucideIcons.check,
            isFullWidth: true,
            onPressed: () => Navigator.pop(sheetCtx, true),
          ),
          const SizedBox(height: AppSpacing.sm),
          DocoraButton(
            label: 'Not Now',
            variant: DocoraButtonVariant.ghost,
            isFullWidth: true,
            onPressed: () => Navigator.pop(sheetCtx, false),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
