import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Search field designed for Docora with clear action, filter trigger, and haptics.
class DocoraSearchField extends StatefulWidget {
  const DocoraSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search documents...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final bool autofocus;

  @override
  State<DocoraSearchField> createState() => _DocoraSearchFieldState();
}

class _DocoraSearchFieldState extends State<DocoraSearchField> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Icon(
            LucideIcons.search,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_hasText)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18),
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
              tooltip: 'Clear',
            ),
          if (widget.onFilterTap != null) ...[
            Container(
              height: 20,
              width: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            IconButton(
              icon: Stack(
                children: [
                  Icon(
                    LucideIcons.sliders_horizontal,
                    size: 18,
                    color: widget.hasActiveFilters
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  if (widget.hasActiveFilters)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onFilterTap!();
              },
              tooltip: 'Filters',
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}
