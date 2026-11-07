import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Docora bottom navigation (v2, matched to the reference screenshot).
///
/// Layout: 5 equal slots -> Home | Files | [centre + button] | Tools | Settings
/// - Bar is BLACK in light theme (as in the reference) and a lifted dark grey
///   with a 1dp top border in dark theme.
/// - Centre button: accent circle with a thick ring. Ring is white in light
///   theme, so it merges with the page and the black bar looks notched around
///   it. In dark theme the ring takes the scaffold colour (same notch effect).
///   Override with [ringColor] if you want it always white.
/// - Accent = [accent] or Theme.colorScheme.primary. Active tab and the centre
///   button follow it. "+" flips white/dark automatically for light accents.

class DocoraNavItem {
  const DocoraNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const List<DocoraNavItem> kDocoraNavItems = [
  DocoraNavItem(
      icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
  DocoraNavItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: 'Files'),
  DocoraNavItem(
      icon: Icons.build_outlined,
      activeIcon: Icons.build_rounded,
      label: 'Tools'),
  DocoraNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings'),
];

class DocoraBottomNav extends StatelessWidget {
  const DocoraBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
    super.key,
    this.accent,
    this.ringColor,
    this.items = kDocoraNavItems,
    this.addLabel = 'Add',
  });

  /// 0..3 = Home, Files, Tools, Settings. The centre button has no index.
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;
  final Color? accent;
  final Color? ringColor;
  final List<DocoraNavItem> items;
  final String addLabel;

  // Geometry in dp (measured from the reference screenshot)
  static const double _barHeight = 64;
  static const double _fabInner = 60;
  static const double _ring = 4;
  static const double _fabOuter = _fabInner + _ring * 2; // 68
  static const double _lift = 13; // ring top sits 13dp above bar top
  // Button centre = _fabOuter / 2 - _lift = 21dp below the bar's top edge.

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'DocoraBottomNav needs exactly 4 items');

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accentColor = accent ?? theme.colorScheme.primary;

    final barColor = dark ? const Color(0xFF1A1D23) : const Color(0xFF101114);
    final borderColor = const Color(0xFF2B2F38);
    final inactive = dark ? const Color(0xFF98A2B3) : const Color(0xFFD0D5DD);
    final ring =
        ringColor ?? (dark ? theme.scaffoldBackgroundColor : Colors.white);

    final activeFg = _lightenToContrast(accentColor, barColor);
    final onAccent =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
            ? Colors.white
            : const Color(0xFF101828);

    final inset = MediaQuery.of(context).padding.bottom;

    Widget tab(int i) => Expanded(
          child: _NavTab(
            item: items[i],
            selected: currentIndex == i,
            activeColor: activeFg,
            inactiveColor: inactive,
            onTap: () {
              if (i != currentIndex) HapticFeedback.selectionClick();
              onTap(i);
            },
          ),
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Keeps the system gesture handle white on the black bar.
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: barColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: SizedBox(
        height: _lift + _barHeight + inset,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _barHeight + inset,
              child: Material(
                color: barColor,
                shape: Border(
                  top: dark
                      ? BorderSide(color: borderColor)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: inset),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.15,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tab(0),
                        tab(1),
                        const Expanded(child: SizedBox()), // centre slot
                        tab(2),
                        tab(3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  button: true,
                  label: addLabel,
                  child: Container(
                    width: _fabOuter,
                    height: _fabOuter,
                    padding: const EdgeInsets.all(_ring),
                    decoration:
                        BoxDecoration(color: ring, shape: BoxShape.circle),
                    child: Material(
                      color: accentColor,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onAddTap();
                        },
                        child: Center(
                          child: Icon(Icons.add, size: 30, color: onAccent),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final DocoraNavItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: ExcludeSemantics(
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          splashColor: activeColor.withAlpha(40),
          highlightColor: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: target),
              duration: const Duration(milliseconds: 200),
              builder: (context, color, _) {
                final c = color ?? target;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(selected ? item.activeIcon : item.icon,
                        size: 24, color: c),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.33,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: c,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The bar is always dark, so dark accents are lightened until they reach
/// [minRatio] contrast. Bright accents (lime, orange) are left untouched.
Color _lightenToContrast(Color c, Color bg, {double minRatio = 3.5}) {
  double ratio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final hi = l1 > l2 ? l1 : l2;
    final lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  var out = c;
  for (var i = 0; i < 12 && ratio(out, bg) < minRatio; i++) {
    out = Color.lerp(out, Colors.white, 0.12)!;
  }
  return out;
}
