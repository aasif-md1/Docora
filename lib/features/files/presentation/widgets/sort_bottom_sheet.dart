import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/widgets/docora_bottom_sheet.dart';
import 'package:docora/domain/repositories/document_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet allowing the user to select document sort criteria.
class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({
    required this.currentSort,
    required this.onSortSelected,
    super.key,
  });

  final DocumentSortOption currentSort;
  final ValueChanged<DocumentSortOption> onSortSelected;

  static Future<void> show({
    required BuildContext context,
    required DocumentSortOption currentSort,
    required ValueChanged<DocumentSortOption> onSortSelected,
  }) {
    AppMotion.subtleHaptic();
    return DocoraBottomSheet.show<void>(
      context: context,
      title: 'Sort Documents By',
      showCloseButton: true,
      builder: (ctx) => SortBottomSheet(
        currentSort: currentSort,
        onSortSelected: (sort) {
          onSortSelected(sort);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSortTile(
          context,
          option: DocumentSortOption.dateModifiedDesc,
          icon: LucideIcons.calendar_arrow_down,
          label: 'Date Modified (Newest first)',
          activeColor: colorScheme.primary,
        ),
        _buildSortTile(
          context,
          option: DocumentSortOption.dateModifiedAsc,
          icon: LucideIcons.calendar_arrow_up,
          label: 'Date Modified (Oldest first)',
          activeColor: colorScheme.primary,
        ),
        const Divider(height: 1),
        _buildSortTile(
          context,
          option: DocumentSortOption.nameAsc,
          icon: LucideIcons.arrow_down_a_z,
          label: 'File Name (A to Z)',
          activeColor: colorScheme.primary,
        ),
        _buildSortTile(
          context,
          option: DocumentSortOption.nameDesc,
          icon: LucideIcons.arrow_down_z_a,
          label: 'File Name (Z to A)',
          activeColor: colorScheme.primary,
        ),
        const Divider(height: 1),
        _buildSortTile(
          context,
          option: DocumentSortOption.sizeDesc,
          icon: LucideIcons.arrow_down_1_0,
          label: 'File Size (Largest first)',
          activeColor: colorScheme.primary,
        ),
        _buildSortTile(
          context,
          option: DocumentSortOption.sizeAsc,
          icon: LucideIcons.arrow_down_0_1,
          label: 'File Size (Smallest first)',
          activeColor: colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildSortTile(
    BuildContext context, {
    required DocumentSortOption option,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = currentSort == option;

    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(
              LucideIcons.check,
              size: 18,
              color: activeColor,
            )
          : null,
      onTap: () {
        AppMotion.subtleHaptic();
        onSortSelected(option);
      },
    );
  }
}
