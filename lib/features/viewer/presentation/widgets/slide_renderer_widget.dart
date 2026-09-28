import 'dart:math' as math;
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/domain/models/presentation_models.dart';
import 'package:docora/features/viewer/presentation/widgets/slide_shape_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Renders a true 2D presentation slide canvas preserving exact slide aspect ratio (16:9 or 4:3),
/// background artwork/colors, absolute positioned shapes, tables, divider lines, images,
/// and interactive pinch-to-zoom fidelity.
class SlideRendererWidget extends StatelessWidget {
  const SlideRendererWidget({
    required this.slide,
    this.aspectRatio = 16 / 9,
    this.readingMode = PdfReadingMode.normal,
    this.isFullscreen = false,
    super.key,
  });

  final PresentationSlide slide;
  final double aspectRatio;
  final PdfReadingMode readingMode;
  final bool isFullscreen;

  /// Check if the slide canvas has a dark background to ensure optimal text contrast.
  bool _isDarkBackground(BuildContext context) {
    if (readingMode == PdfReadingMode.dark) return true;
    if (readingMode == PdfReadingMode.sepia) return false;

    if (slide.backgroundColor != null) {
      return slide.backgroundColor!.computeLuminance() < 0.5;
    }
    if (slide.backgroundImageBytes != null) {
      return true;
    }
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _getFallbackCanvasColor(BuildContext context) {
    switch (readingMode) {
      case PdfReadingMode.dark:
        return const Color(0xFF13131A);
      case PdfReadingMode.sepia:
        return const Color(0xFFFAF3E3);
      case PdfReadingMode.grayscale:
        return Colors.white;
      case PdfReadingMode.normal:
        return slide.backgroundColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF13131A)
                : const Color(0xFFFFFFFF));
    }

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkCanvas = _isDarkBackground(context);
    final canvasColor = _getFallbackCanvasColor(context);
    final defaultTextColor = isDarkCanvas ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final effectiveRatio = aspectRatio > 0 ? aspectRatio : (16 / 9);
        double targetWidth = availableWidth;
        double targetHeight = availableWidth / effectiveRatio;

        if (targetHeight > availableHeight) {
          targetHeight = availableHeight;
          targetWidth = availableHeight * effectiveRatio;
        }

        // Scale factor relative to standard 960x540 base slide canvas
        final scale = targetWidth / 960.0;

        final canvasContent = Container(
          width: targetWidth,
          height: targetHeight,
          decoration: BoxDecoration(
            gradient: (slide.gradientColors != null && slide.gradientColors!.length >= 2)
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: slide.gradientColors!,
                  )
                : null,
            color: (slide.gradientColors != null && slide.gradientColors!.length >= 2)
                ? null
                : canvasColor,
            borderRadius: BorderRadius.circular(isFullscreen ? 0 : 12),
            boxShadow: isFullscreen
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDarkCanvas ? 100 : 40),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
            border: isFullscreen
                ? null
                : Border.all(
                    color: isDarkCanvas
                        ? Colors.white.withAlpha(25)
                        : Colors.black.withAlpha(18),
                  ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isFullscreen ? 0 : 12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background image (if present in slide or inherited from layout/master)
                if (slide.backgroundImageBytes != null)
                  Positioned.fill(
                    child: Image.memory(
                      slide.backgroundImageBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),

                // 2. Elements rendered in exact Z-order
                if (slide.elements.isNotEmpty)
                  ...slide.elements.map((el) => _buildVisualElement(
                        context,
                        el,
                        targetWidth,
                        targetHeight,
                        scale,
                        defaultTextColor,
                        isDarkCanvas,
                      ))
                else ...[
                  // Fallback for presentations parsed without unified elements
                  ...slide.images.map((img) => _buildImage(img, targetWidth, targetHeight)),
                  ...slide.shapes.map((shape) => _buildShape(
                        shape,
                        targetWidth,
                        targetHeight,
                        scale,
                        defaultTextColor,
                        isDarkCanvas,
                      )),
                  ...slide.tables.map((table) => _buildTableWrapper(
                        table,
                        targetWidth,
                        targetHeight,
                        scale,
                        defaultTextColor,
                      )),
                ],

                // 3. Render explicit slide title if provided and not already included in shapes/elements
                if (slide.title != null &&
                    slide.title!.trim().isNotEmpty &&
                    !slide.shapes.any((s) => s.plainText.contains(slide.title!)) &&
                    !slide.elements.any((e) => e is SlideShapeElement && e.shape.plainText.contains(slide.title!)))
                  Positioned(
                    left: 0.06 * targetWidth,
                    top: 0.06 * targetHeight,
                    width: 0.88 * targetWidth,
                    child: Text(
                      slide.title!,
                      style: TextStyle(
                        fontSize: math.max(22.0 * scale, 12.0),
                        fontWeight: FontWeight.bold,
                        color: isDarkCanvas ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),

                // Empty slide indicator if completely empty
                if (slide.shapes.isEmpty &&
                    slide.images.isEmpty &&
                    slide.tables.isEmpty &&
                    slide.elements.isEmpty &&
                    slide.backgroundImageBytes == null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.presentation, size: 40 * scale, color: theme.colorScheme.outline),
                        SizedBox(height: 8 * scale),
                        Text(
                          'Empty Slide',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );

        return Center(
          child: Padding(
            padding: isFullscreen ? EdgeInsets.zero : const EdgeInsets.all(8.0),
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              clipBehavior: Clip.none,
              child: canvasContent,
            ),
          ),
        );
      },
    );
  }

  /// Build an individual visual element according to its concrete type.
  Widget _buildVisualElement(
    BuildContext context,
    SlideVisualElement element,
    double targetWidth,
    double targetHeight,
    double scale,
    Color defaultTextColor,
    bool isDarkCanvas,
  ) {
    if (element is SlideImageElement) {
      return _buildImage(element.image, targetWidth, targetHeight, customRect: element.rect);
    } else if (element is SlideShapeElement) {
      return _buildShape(
        element.shape,
        targetWidth,
        targetHeight,
        scale,
        defaultTextColor,
        isDarkCanvas,
        customRect: element.rect,
      );
    } else if (element is SlideTableElement) {
      return _buildTableWrapper(
        element.table,
        targetWidth,
        targetHeight,
        scale,
        defaultTextColor,
        customRect: element.rect,
      );
    }
    return const SizedBox.shrink();
  }

  /// Build an image with 2D bounds.
  Widget _buildImage(
    SlideImage img,
    double targetWidth,
    double targetHeight, {
    SlideRect? customRect,
  }) {
    final r = customRect ??
        img.rect ??
        const SlideRect(left: 0.05, top: 0.05, width: 0.35, height: 0.25);

    Widget imageWidget = Image.memory(
      img.bytes,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

    if (img.rotationDegrees != null && img.rotationDegrees != 0) {
      imageWidget = Transform.rotate(
        angle: img.rotationDegrees! * math.pi / 180.0,
        child: imageWidget,
      );
    }

    return Positioned(
      left: r.left * targetWidth,
      top: r.top * targetHeight,
      width: math.max(r.width * targetWidth, 8.0),
      height: math.max(r.height * targetHeight, 8.0),
      child: imageWidget,
    );
  }

  /// Build a shape or card with 2D bounds.
  Widget _buildShape(
    SlideShape shape,
    double targetWidth,
    double targetHeight,
    double scale,
    Color defaultTextColor,
    bool isDarkCanvas, {
    SlideRect? customRect,
  }) {
    final r = customRect ??
        shape.rect ??
        const SlideRect(left: 0.06, top: 0.15, width: 0.88, height: 0.18);
    final left = r.left * targetWidth;
    final top = r.top * targetHeight;
    final width = math.max(r.width * targetWidth, 4.0);
    final height = math.max(r.height * targetHeight, 4.0);

    // Divider line
    if (shape.isLine) {
      Widget lineWidget = Container(
        color: shape.borderColor ??
            (isDarkCanvas ? Colors.white30 : Colors.black26),
      );
      if (shape.rotationDegrees != null && shape.rotationDegrees != 0) {
        lineWidget = Transform.rotate(
          angle: shape.rotationDegrees! * math.pi / 180.0,
          child: lineWidget,
        );
      }
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: math.max((shape.borderWidth ?? 1.2) * scale, 1.0),
        child: lineWidget,
      );
    }

    // Determine shape text color contrast
    Color shapeTextColor = defaultTextColor;
    if (shape.backgroundColor != null) {
      final cardLuminance = shape.backgroundColor!.computeLuminance();
      shapeTextColor = cardLuminance > 0.5
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC);
    } else if (shape.gradientColors != null && shape.gradientColors!.isNotEmpty) {
      final cardLuminance = shape.gradientColors!.first.computeLuminance();
      shapeTextColor = cardLuminance > 0.5
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC);
    } else if (shape.title && isDarkCanvas) {
      shapeTextColor = const Color(0xFF38BDF8);
    }

    final hasBackground = shape.backgroundColor != null ||
        (shape.gradientColors != null && shape.gradientColors!.length >= 2);

    final clipper = SlideShapeGeometry.getClipper(
      shape.shapeType,
      customPathCommands: shape.customPathCommands,
    );

    BorderRadius? shapeBorderRadius;
    if (shape.shapeType == 'ellipse') {
      shapeBorderRadius = BorderRadius.all(Radius.elliptical(width / 2, height / 2));
    } else if (shape.borderRadius != null) {
      shapeBorderRadius = BorderRadius.circular(shape.borderRadius! * scale);
    } else if (hasBackground && clipper == null) {
      shapeBorderRadius = BorderRadius.circular(6.0 * scale);
    }

    Widget shapeWidget = Container(
      decoration: BoxDecoration(
        gradient: (shape.gradientColors != null && shape.gradientColors!.length >= 2)
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: shape.gradientColors!,
              )
            : null,
        color: (shape.gradientColors != null && shape.gradientColors!.length >= 2)
            ? null
            : shape.backgroundColor,
        borderRadius: clipper == null ? shapeBorderRadius : null,
        border: (shape.borderColor != null && clipper == null)
            ? Border.all(
                color: shape.borderColor!,
                width: math.max((shape.borderWidth ?? 1.0) * scale, 0.8),
              )
            : null,
      ),
      padding: hasBackground
          ? EdgeInsets.symmetric(
              horizontal: math.max(8.0 * scale, 4.0),
              vertical: math.max(6.0 * scale, 3.0),
            )
          : EdgeInsets.zero,
      alignment: shape.anchorCenter ? Alignment.center : Alignment.topLeft,
      child: _buildShapeContent(
        shape,
        scale,
        shapeTextColor,
      ),
    );

    if (clipper != null) {
      shapeWidget = ClipPath(
        clipper: clipper,
        child: shapeWidget,
      );
      if (shape.borderColor != null) {
        shapeWidget = CustomPaint(
          foregroundPainter: SlideShapeBorderPainter(
            clipper: clipper,
            borderColor: shape.borderColor!,
            borderWidth: math.max((shape.borderWidth ?? 1.5) * scale, 1.0),
          ),
          child: shapeWidget,
        );
      }
    }

    if (shape.rotationDegrees != null && shape.rotationDegrees != 0) {
      shapeWidget = Transform.rotate(
        angle: shape.rotationDegrees! * math.pi / 180.0,
        child: shapeWidget,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: shapeWidget,
    );
  }


  /// Build text paragraphs inside a shape.
  Widget _buildShapeContent(
    SlideShape shape,
    double scale,
    Color defaultColor,
  ) {
    if (shape.paragraphs.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: shape.paragraphs.map((p) {
          final isTitle = shape.title;
          if (p.isBullet || p.level > 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.0 * scale),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: p.level * 8.0 * scale,
                      right: 4.0 * scale,
                      top: 4.0 * scale,
                    ),
                    child: Container(
                      width: 4 * scale,
                      height: 4 * scale,
                      decoration: BoxDecoration(
                        color: defaultColor.withAlpha(200),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildParagraphText(p, isTitle, scale, defaultColor),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 2.0 * scale),
            child: _buildParagraphText(p, isTitle, scale, defaultColor),
          );
        }).toList(),
      ),
    );
  }

  TextStyle _resolveTextStyle({
    required SlideTextRun run,
    required bool isTitle,
    required double scale,
    required Color defaultColor,
  }) {
    // Realistic PowerPoint font sizes: titles are 36-40pt, body text is 18-20pt by default
    final baseSize = run.fontSize ?? (isTitle ? 36.0 : 18.0);
    double fontSize = baseSize * scale;
    fontSize = math.max(fontSize, 7.5);

    final isHeading = isTitle || baseSize >= 22.0;

    // Font-family fallback detection based on font characteristics
    final requestedFont = run.fontFamily?.trim();
    List<String> fallbacks = const ['Roboto', 'sans-serif'];
    if (requestedFont != null && requestedFont.isNotEmpty) {
      final lower = requestedFont.toLowerCase();
      if (lower.contains('serif') ||
          lower.contains('times') ||
          lower.contains('georgia') ||
          lower.contains('cambria') ||
          lower.contains('garamond')) {
        fallbacks = [requestedFont, 'serif', 'Noto Serif', 'Times New Roman'];
      } else if (lower.contains('mono') ||
          lower.contains('courier') ||
          lower.contains('consolas')) {
        fallbacks = [requestedFont, 'monospace', 'Courier New'];
      } else if (isHeading) {
        fallbacks = [requestedFont, 'sans-serif-medium', 'sans-serif', 'Roboto'];
      } else {
        fallbacks = [requestedFont, 'sans-serif', 'Roboto'];
      }
    } else if (isHeading) {
      fallbacks = const ['sans-serif-medium', 'sans-serif', 'Roboto'];
    }

    FontWeight fontWeight;
    if (run.isBold) {
      fontWeight = FontWeight.bold;
    } else if (isTitle) {
      fontWeight = FontWeight.w700;
    } else if (isHeading) {
      fontWeight = FontWeight.w600;
    } else {
      fontWeight = FontWeight.normal;
    }

    return TextStyle(
      fontFamily: requestedFont,
      fontFamilyFallback: fallbacks,
      fontWeight: fontWeight,
      fontStyle: run.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: run.isUnderline ? TextDecoration.underline : null,
      fontSize: fontSize,
      color: run.color ?? defaultColor,
      height: isTitle ? 1.15 : 1.25,
      letterSpacing: isTitle ? -0.2 : 0.0,
    );
  }

  Widget _buildParagraphText(SlideParagraph p, bool isTitle, double scale, Color defaultColor) {
    if (p.runs.length == 1) {
      final r = p.runs.first;
      return Text(
        r.text,
        style: _resolveTextStyle(
          run: r,
          isTitle: isTitle,
          scale: scale,
          defaultColor: defaultColor,
        ),
        textAlign: p.alignment,
      );
    }

    return Text.rich(
      TextSpan(
        children: p.runs.map((r) => _buildSpan(r, isTitle, scale, defaultColor)).toList(),
      ),
      textAlign: p.alignment,
    );
  }

  InlineSpan _buildSpan(
    SlideTextRun r,
    bool isTitle,
    double scale,
    Color defaultColor,
  ) =>
      TextSpan(
        text: r.text,
        style: _resolveTextStyle(
          run: r,
          isTitle: isTitle,
          scale: scale,
          defaultColor: defaultColor,
        ),
      );


  /// Build wrapper for a table element.
  Widget _buildTableWrapper(
    SlideTable table,
    double targetWidth,
    double targetHeight,
    double scale,
    Color defaultTextColor, {
    SlideRect? customRect,
  }) {
    final r = customRect ??
        table.rect ??
        const SlideRect(left: 0.06, top: 0.62, width: 0.88, height: 0.22);
    return Positioned(
      left: r.left * targetWidth,
      top: r.top * targetHeight,
      width: math.max(r.width * targetWidth, 40.0),
      child: _buildTable(table, scale, defaultTextColor),
    );
  }

  /// Build structured presentation table (e.g. 3-column professors attribution).
  Widget _buildTable(
    SlideTable table,
    double scale,
    Color defaultColor,
  ) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final numCols = table.rows.first.cells.length;
    final Map<int, TableColumnWidth> colWidths = {};
    if (table.columnWidthRatios != null && table.columnWidthRatios!.length == numCols) {
      for (int i = 0; i < numCols; i++) {
        colWidths[i] = FlexColumnWidth(table.columnWidthRatios![i]);
      }
    } else {
      for (int i = 0; i < numCols; i++) {
        colWidths[i] = const FlexColumnWidth();
      }
    }

    return Table(
      columnWidths: colWidths,
      children: table.rows.map((row) => TableRow(
        children: row.cells.map((cell) {
          Color cellTextColor = defaultColor;
          if (cell.backgroundColor != null) {
            final lum = cell.backgroundColor!.computeLuminance();
            cellTextColor = lum > 0.5 ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
          }

          return Container(
            decoration: BoxDecoration(
              color: cell.backgroundColor,
              border: cell.borderColor != null
                  ? Border.all(color: cell.borderColor!, width: 0.8 * scale)
                  : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 4.0 * scale,
              vertical: 2.0 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: cell.paragraphs.map((p) => Padding(
                padding: EdgeInsets.only(bottom: 2.0 * scale),
                child: Text.rich(
                  TextSpan(
                    children: p.runs.map((r) => _buildSpan(r, false, scale, cellTextColor)).toList(),
                  ),
                  textAlign: p.alignment,
                ),
              )).toList(),
            ),
          );
        }).toList(),
      )).toList(),
    );
  }
}
