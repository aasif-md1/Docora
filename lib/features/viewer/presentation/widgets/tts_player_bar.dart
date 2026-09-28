import 'package:docora/core/services/tts_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TtsPlayerBar extends ConsumerWidget {
  const TtsPlayerBar({
    required this.onClose,
    super.key,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      color: colorScheme.surfaceContainerHigh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.volume_2, size: 20, color: AppColors.primary500),
            const SizedBox(width: 10),
            Text(
              tts.isPlaying ? 'Reading Aloud...' : 'Paused',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),

            // Play / Pause
            IconButton(
              icon: Icon(tts.isPlaying ? LucideIcons.pause : LucideIcons.play),
              onPressed: () {
                AppMotion.subtleHaptic();
                if (tts.isPlaying) {
                  tts.pause();
                } else {
                  tts.resume();
                }
              },
            ),

            // Speed cycle
            TextButton(
              onPressed: () {
                AppMotion.subtleHaptic();
                final current = tts.rate;
                final next = current >= 0.8 ? 0.4 : current + 0.15;
                tts.setRate(next);
              },
              child: Text(
                '${(tts.rate * 2).toStringAsFixed(1)}x',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // Stop / Close
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18),
              onPressed: () {
                AppMotion.subtleHaptic();
                tts.stop();
                onClose();
              },
            ),
          ],
        ),
      ),
    );
  }
}
