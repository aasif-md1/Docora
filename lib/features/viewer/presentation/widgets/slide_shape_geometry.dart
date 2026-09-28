import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Provides custom vector clipping and drawing paths for PowerPoint preset geometries
/// such as arrows, flowcharts, diamonds, chevrons, hexagons, cylinders, callouts, and custom DrawingML paths.
class SlideShapeGeometry {
  const SlideShapeGeometry._();

  /// Returns a [CustomClipper<Path>] for preset geometry [shapeType] or custom path [customPathCommands].
  static CustomClipper<Path>? getClipper(String? shapeType, {List<String>? customPathCommands}) {
    if (customPathCommands != null && customPathCommands.isNotEmpty) {
      return CustomVectorPathClipper(customPathCommands);
    }
    if (shapeType == null) return null;

    return switch (shapeType) {
      'ellipse' || 'circle' || 'oval' => const _EllipseClipper(),
      'rightArrow' ||
      'leftArrow' ||
      'upArrow' ||
      'downArrow' ||
      'leftRightArrow' ||
      'upDownArrow' ||
      'bentArrow' ||
      'curvedRightArrow' ||
      'curvedLeftArrow' ||
      'curvedUpArrow' ||
      'curvedDownArrow' ||
      'bentUpArrow' ||
      'uturnArrow' ||
      'circularArrow' ||
      'quadArrow' ||
      'chevron' ||
      'homePlate' ||
      'notchedRightArrow' ||
      'stripedRightArrow' =>
        _ArrowClipper(shapeType),
      'diamond' || 'flowChartDecision' => const _DiamondClipper(),
      'parallelogram' || 'flowChartInputOutput' => const _ParallelogramClipper(),
      'trapezoid' => const _TrapezoidClipper(),
      'pentagon' => const _PolygonClipper(5),
      'hexagon' || 'flowChartPreparation' => const _PolygonClipper(6),
      'heptagon' => const _PolygonClipper(7),
      'octagon' => const _PolygonClipper(8),
      'decagon' => const _PolygonClipper(10),
      'dodecagon' => const _PolygonClipper(12),
      'triangle' || 'rtTriangle' => _TriangleClipper(shapeType),
      'star4' => const _StarClipper(4),
      'star5' => const _StarClipper(5),
      'star6' => const _StarClipper(6),
      'star8' => const _StarClipper(8),
      'star10' => const _StarClipper(10),
      'star12' => const _StarClipper(12),
      'wedgeRectCallout' ||
      'wedgeRoundRectCallout' ||
      'wedgeRrectCallout' ||
      'wedgeEllipseCallout' ||
      'callout' ||
      'callout1' ||
      'callout2' ||
      'callout3' =>
        _CalloutClipper(shapeType),
      'heart' => const _HeartClipper(),
      'cloud' || 'cloudCallout' => const _CloudClipper(),
      'lightningBolt' => const _LightningClipper(),
      'sun' => const _SunClipper(),
      'donut' => const _DonutClipper(),
      'can' || 'cylinder' || 'flowChartCollate' => const _CylinderClipper(),
      'cube' => const _CubeClipper(),
      'blockArc' || 'arc' || 'pie' || 'chord' => _ArcPieceClipper(shapeType),
      'teardrop' => const _TeardropClipper(),
      'frame' || 'halfFrame' || 'corner' => _FrameClipper(shapeType),
      'foldedCorner' => const _FoldedCornerClipper(),
      'ribbon' || 'ribbon2' => _RibbonClipper(shapeType),
      'wave' || 'doubleWave' || 'flowChartDocument' => _WaveClipper(shapeType),
      'plaque' => const _PlaqueClipper(),
      'flowChartTerminator' => const _CapsuleClipper(),
      'roundRect' || 'round1Rect' || 'round2SameRect' || 'round2DiagRect' || 'snip1Rect' || 'snip2SameRect' || 'snip2DiagRect' || 'snipRoundRect' =>
        _SnipRoundRectClipper(shapeType),
      _ => null,
    };
  }

  /// Returns true if [shapeType] is a special vector geometry that shouldn't use standard box borders.
  static bool isVectorShape(String? shapeType, {bool hasCustomPath = false}) {
    if (hasCustomPath) return true;
    if (shapeType == null) return false;
    return const {
      'ellipse', 'circle', 'oval',
      'rightArrow', 'leftArrow', 'upArrow', 'downArrow', 'leftRightArrow', 'upDownArrow',
      'bentArrow', 'curvedRightArrow', 'curvedLeftArrow', 'curvedUpArrow', 'curvedDownArrow',
      'bentUpArrow', 'uturnArrow', 'circularArrow', 'quadArrow',
      'chevron', 'homePlate', 'notchedRightArrow', 'stripedRightArrow',
      'diamond', 'flowChartDecision', 'parallelogram', 'flowChartInputOutput',
      'trapezoid', 'pentagon', 'hexagon', 'flowChartPreparation', 'heptagon', 'octagon', 'decagon', 'dodecagon',
      'triangle', 'rtTriangle', 'star4', 'star5', 'star6', 'star8', 'star10', 'star12',
      'wedgeRectCallout', 'wedgeRoundRectCallout', 'wedgeRrectCallout', 'wedgeEllipseCallout', 'callout',
      'callout1', 'callout2', 'callout3',
      'heart', 'cloud', 'cloudCallout', 'lightningBolt', 'sun', 'donut',
      'can', 'cylinder', 'cube',
      'blockArc', 'arc', 'pie', 'chord', 'teardrop', 'frame', 'halfFrame', 'corner',
      'foldedCorner', 'ribbon', 'ribbon2', 'wave', 'doubleWave', 'flowChartDocument', 'plaque',
      'flowChartTerminator',
      'roundRect', 'round1Rect', 'round2SameRect', 'round2DiagRect', 'snip1Rect', 'snip2SameRect', 'snip2DiagRect', 'snipRoundRect',
    }.contains(shapeType);
  }
}

/// Dynamic clipper that executes normalized DrawingML vector path commands.
class CustomVectorPathClipper extends CustomClipper<Path> {
  const CustomVectorPathClipper(this.commands);
  final List<String> commands;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (commands.isEmpty) return path;

    double vbW = size.width;
    double vbH = size.height;
    int startIndex = 0;

    if (commands.first.startsWith('VIEWBOX')) {
      final parts = commands.first.split(' ');
      if (parts.length >= 3) {
        vbW = double.tryParse(parts[1]) ?? size.width;
        vbH = double.tryParse(parts[2]) ?? size.height;
      }
      startIndex = 1;
    }

    final scaleX = vbW > 0 ? (size.width / vbW) : 1.0;
    final scaleY = vbH > 0 ? (size.height / vbH) : 1.0;

    double currX = 0.0;
    double currY = 0.0;

    for (int i = startIndex; i < commands.length; i++) {
      final cmd = commands[i].trim();
      final parts = cmd.split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;
      final type = parts[0];

      if (type == 'M' && parts.length >= 3) {
        currX = (double.tryParse(parts[1]) ?? 0) * scaleX;
        currY = (double.tryParse(parts[2]) ?? 0) * scaleY;
        path.moveTo(currX, currY);
      } else if (type == 'L' && parts.length >= 3) {
        currX = (double.tryParse(parts[1]) ?? 0) * scaleX;
        currY = (double.tryParse(parts[2]) ?? 0) * scaleY;
        path.lineTo(currX, currY);
      } else if (type == 'C' && parts.length >= 7) {
        final x1 = (double.tryParse(parts[1]) ?? 0) * scaleX;
        final y1 = (double.tryParse(parts[2]) ?? 0) * scaleY;
        final x2 = (double.tryParse(parts[3]) ?? 0) * scaleX;
        final y2 = (double.tryParse(parts[4]) ?? 0) * scaleY;
        currX = (double.tryParse(parts[5]) ?? 0) * scaleX;
        currY = (double.tryParse(parts[6]) ?? 0) * scaleY;
        path.cubicTo(x1, y1, x2, y2, currX, currY);
      } else if (type == 'Q' && parts.length >= 5) {
        final x1 = (double.tryParse(parts[1]) ?? 0) * scaleX;
        final y1 = (double.tryParse(parts[2]) ?? 0) * scaleY;
        currX = (double.tryParse(parts[3]) ?? 0) * scaleX;
        currY = (double.tryParse(parts[4]) ?? 0) * scaleY;
        path.quadraticBezierTo(x1, y1, currX, currY);
      } else if (type == 'A' && parts.length >= 5) {
        final wR = (double.tryParse(parts[1]) ?? 0) * scaleX;
        final hR = (double.tryParse(parts[2]) ?? 0) * scaleY;
        final stAng = (double.tryParse(parts[3]) ?? 0) * math.pi / 180.0;
        final swAng = (double.tryParse(parts[4]) ?? 0) * math.pi / 180.0;
        if (wR > 0 && hR > 0) {
          // DrawingML arc center is computed from current point and start angle
          final cx = currX - wR * math.cos(stAng);
          final cy = currY - hR * math.sin(stAng);
          path.arcTo(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: wR * 2,
              height: hR * 2,
            ),
            stAng,
            swAng,
            false,
          );
          currX = cx + wR * math.cos(stAng + swAng);
          currY = cy + hR * math.sin(stAng + swAng);
        }
      } else if (type == 'Z') {
        path.close();
      }
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomVectorPathClipper oldClipper) => true;
}

class _EllipseClipper extends CustomClipper<Path> {
  const _EllipseClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ArrowClipper extends CustomClipper<Path> {
  const _ArrowClipper(this.type);
  final String type;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    switch (type) {
      case 'rightArrow':
      case 'notchedRightArrow':
      case 'stripedRightArrow':
        final headLen = math.min(w * 0.45, math.max(h * 0.75, 14.0));
        final stemTop = h * 0.28;
        final stemBottom = h * 0.72;
        final headX = w - headLen;

        path.moveTo(0, stemTop);
        path.lineTo(headX, stemTop);
        path.lineTo(headX, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(headX, h);
        path.lineTo(headX, stemBottom);
        path.lineTo(0, stemBottom);
        if (type == 'notchedRightArrow') {
          path.lineTo(headLen * 0.35, h * 0.5);
        }
        path.close();

      case 'leftArrow':
        final headLen = math.min(w * 0.45, math.max(h * 0.75, 14.0));
        final stemTop = h * 0.28;
        final stemBottom = h * 0.72;

        path.moveTo(w, stemTop);
        path.lineTo(headLen, stemTop);
        path.lineTo(headLen, 0);
        path.lineTo(0, h * 0.5);
        path.lineTo(headLen, h);
        path.lineTo(headLen, stemBottom);
        path.lineTo(w, stemBottom);
        path.close();

      case 'upArrow':
        final headH = math.min(h * 0.45, math.max(w * 0.75, 14.0));
        final stemLeft = w * 0.28;
        final stemRight = w * 0.72;

        path.moveTo(w * 0.5, 0);
        path.lineTo(w, headH);
        path.lineTo(stemRight, headH);
        path.lineTo(stemRight, h);
        path.lineTo(stemLeft, h);
        path.lineTo(stemLeft, headH);
        path.lineTo(0, headH);
        path.close();

      case 'downArrow':
        final headH = math.min(h * 0.45, math.max(w * 0.75, 14.0));
        final stemLeft = w * 0.28;
        final stemRight = w * 0.72;
        final headY = h - headH;

        path.moveTo(stemLeft, 0);
        path.lineTo(stemRight, 0);
        path.lineTo(stemRight, headY);
        path.lineTo(w, headY);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, headY);
        path.lineTo(stemLeft, headY);
        path.close();

      case 'leftRightArrow':
        final headLen = math.min(w * 0.28, math.max(h * 0.6, 12.0));
        final stemTop = h * 0.30;
        final stemBottom = h * 0.70;

        path.moveTo(0, h * 0.5);
        path.lineTo(headLen, 0);
        path.lineTo(headLen, stemTop);
        path.lineTo(w - headLen, stemTop);
        path.lineTo(w - headLen, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w - headLen, h);
        path.lineTo(w - headLen, stemBottom);
        path.lineTo(headLen, stemBottom);
        path.lineTo(headLen, h);
        path.close();

      case 'upDownArrow':
        final headH = math.min(h * 0.28, math.max(w * 0.6, 12.0));
        final stemLeft = w * 0.30;
        final stemRight = w * 0.70;

        path.moveTo(w * 0.5, 0);
        path.lineTo(w, headH);
        path.lineTo(stemRight, headH);
        path.lineTo(stemRight, h - headH);
        path.lineTo(w, h - headH);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h - headH);
        path.lineTo(stemLeft, h - headH);
        path.lineTo(stemLeft, headH);
        path.lineTo(0, headH);
        path.close();

      case 'chevron':
      case 'homePlate':
        final tip = math.min(w * 0.35, h * 0.5);
        path.moveTo(0, 0);
        path.lineTo(w - tip, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w - tip, h);
        path.lineTo(0, h);
        if (type == 'chevron') {
          path.lineTo(tip, h * 0.5);
        }
        path.close();

      case 'bentArrow':
        final headLen = math.min(w * 0.40, math.max(h * 0.5, 14.0));
        final stemW = w * 0.35;
        path.moveTo(0, h);
        path.lineTo(stemW, h);
        path.lineTo(stemW, headLen);
        path.lineTo(w - headLen, headLen);
        path.lineTo(w - headLen, headLen * 1.5);
        path.lineTo(w, headLen * 0.5);
        path.lineTo(w - headLen, 0);
        path.lineTo(w - headLen, headLen * 0.5);
        path.lineTo(0, headLen * 0.5);
        path.close();

      case 'curvedRightArrow':
        final headLen = math.min(w * 0.40, math.max(h * 0.6, 14.0));
        path.moveTo(0, h * 0.7);
        path.quadraticBezierTo(w * 0.35, h * 0.7, w - headLen, h * 0.45);
        path.lineTo(w - headLen, h * 0.7);
        path.lineTo(w, h * 0.35);
        path.lineTo(w - headLen, 0);
        path.lineTo(w - headLen, h * 0.25);
        path.quadraticBezierTo(w * 0.3, h * 0.4, 0, h * 0.4);
        path.close();

      default:
        path.addRect(Rect.fromLTWH(0, 0, w, h));
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _ArrowClipper oldClipper) => oldClipper.type != type;
}

class _DiamondClipper extends CustomClipper<Path> {
  const _DiamondClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ParallelogramClipper extends CustomClipper<Path> {
  const _ParallelogramClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final shift = size.width * 0.2;
    path.moveTo(shift, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - shift, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TrapezoidClipper extends CustomClipper<Path> {
  const _TrapezoidClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final inset = size.width * 0.18;
    path.moveTo(inset, 0);
    path.lineTo(size.width - inset, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PolygonClipper extends CustomClipper<Path> {
  const _PolygonClipper(this.sides);
  final int sides;

  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = cx;
    final ry = cy;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - (math.pi / 2);
      final x = cx + rx * math.cos(angle);
      final y = cy + ry * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _PolygonClipper oldClipper) => oldClipper.sides != sides;
}

class _TriangleClipper extends CustomClipper<Path> {
  const _TriangleClipper(this.type);
  final String type;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (type == 'rtTriangle') {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width * 0.5, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TriangleClipper oldClipper) => oldClipper.type != type;
}

class _StarClipper extends CustomClipper<Path> {
  const _StarClipper(this.points);
  final int points;

  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rOuter = math.min(cx, cy);
    final rInner = rOuter * (points <= 5 ? 0.45 : (points <= 8 ? 0.55 : 0.65));

    final totalPoints = points * 2;
    for (int i = 0; i < totalPoints; i++) {
      final r = (i.isEven) ? rOuter : rInner;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _StarClipper oldClipper) => oldClipper.points != points;
}

class _CalloutClipper extends CustomClipper<Path> {
  const _CalloutClipper(this.type);
  final String type;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final bodyH = h * 0.78;

    final r = (type == 'wedgeRoundRectCallout') ? 12.0 : 0.0;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, bodyH),
      Radius.circular(r),
    ));

    // Tail pointer
    path.moveTo(w * 0.20, bodyH);
    path.lineTo(w * 0.12, h);
    path.lineTo(w * 0.35, bodyH);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CalloutClipper oldClipper) => oldClipper.type != type;
}

class _HeartClipper extends CustomClipper<Path> {
  const _HeartClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.15, h * 0.65, 0, h * 0.4, 0, h * 0.25);
    path.cubicTo(0, h * 0.08, w * 0.18, 0, w * 0.35, 0);
    path.cubicTo(w * 0.42, 0, w * 0.48, h * 0.08, w * 0.5, h * 0.18);
    path.cubicTo(w * 0.52, h * 0.08, w * 0.58, 0, w * 0.65, 0);
    path.cubicTo(w * 0.82, 0, w, h * 0.08, w, h * 0.25);
    path.cubicTo(w, h * 0.4, w * 0.85, h * 0.65, w * 0.5, h * 0.85);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CloudClipper extends CustomClipper<Path> {
  const _CloudClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.2, h * 0.7);
    path.cubicTo(0, h * 0.7, 0, h * 0.4, w * 0.2, h * 0.35);
    path.cubicTo(w * 0.25, h * 0.1, w * 0.55, h * 0.1, w * 0.6, h * 0.35);
    path.cubicTo(w * 0.75, h * 0.2, w, h * 0.3, w * 0.9, h * 0.6);
    path.cubicTo(w, h * 0.7, w * 0.9, h * 0.85, w * 0.75, h * 0.85);
    path.lineTo(w * 0.25, h * 0.85);
    path.cubicTo(w * 0.15, h * 0.85, w * 0.1, h * 0.75, w * 0.2, h * 0.7);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LightningClipper extends CustomClipper<Path> {
  const _LightningClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.55, 0);
    path.lineTo(w * 0.2, h * 0.55);
    path.lineTo(w * 0.5, h * 0.55);
    path.lineTo(w * 0.45, h);
    path.lineTo(w * 0.8, h * 0.45);
    path.lineTo(w * 0.5, h * 0.45);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SunClipper extends CustomClipper<Path> {
  const _SunClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rOuter = math.min(cx, cy);
    final rInner = rOuter * 0.72;

    const rays = 16;
    for (int i = 0; i < rays * 2; i++) {
      final r = (i.isEven) ? rOuter : rInner;
      final angle = i * math.pi / rays;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DonutClipper extends CustomClipper<Path> {
  const _DonutClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.5,
      height: size.height * 0.5,
    );
    path.addOval(inner);
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CylinderClipper extends CustomClipper<Path> {
  const _CylinderClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = h * 0.15;

    path.moveTo(0, r);
    path.quadraticBezierTo(w * 0.5, -r, w, r);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w * 0.5, h + r, 0, h - r);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CubeClipper extends CustomClipper<Path> {
  const _CubeClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final shiftX = w * 0.22;
    final shiftY = h * 0.22;

    path.moveTo(0, shiftY);
    path.lineTo(shiftX, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h - shiftY);
    path.lineTo(w - shiftX, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SnipRoundRectClipper extends CustomClipper<Path> {
  const _SnipRoundRectClipper(this.type);
  final String type;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = math.min(math.min(w, h) * 0.18, 20.0);

    if (type == 'snip1Rect') {
      path.moveTo(r, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.lineTo(0, r);
      path.close();
    } else if (type == 'snip2SameRect') {
      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.lineTo(w, r);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.lineTo(0, r);
      path.close();
    } else if (type == 'snip2DiagRect') {
      path.moveTo(r, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h - r);
      path.lineTo(w - r, h);
      path.lineTo(0, h);
      path.lineTo(0, r);
      path.close();
    } else if (type == 'round2DiagRect') {
      // Office OpenXML DrawingML round2DiagRect:
      // Top-left and bottom-right corners rounded, top-right and bottom-left square.
      path.moveTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h - r);
      path.quadraticBezierTo(w, h, w - r, h);
      path.lineTo(0, h);
      path.lineTo(0, r);
      path.close();
    } else if (type == 'round2SameRect') {
      // Office OpenXML DrawingML round2SameRect:
      // Top-left and top-right rounded, bottom corners square.
      path.moveTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.lineTo(0, r);
      path.close();
    } else if (type == 'round1Rect') {
      path.moveTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.lineTo(0, r);
      path.close();
    } else if (type == 'snipRoundRect') {
      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.lineTo(0, r);
      path.close();
    } else {
      path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)));
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _SnipRoundRectClipper oldClipper) => oldClipper.type != type;
}

class _ArcPieceClipper extends CustomClipper<Path> {
  const _ArcPieceClipper(this.type);
  final String type;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    if (type == 'pie') {
      path.moveTo(w * 0.5, h * 0.5);
      path.arcTo(Rect.fromLTWH(0, 0, w, h), -math.pi / 2, 1.5 * math.pi, false);
      path.close();
    } else if (type == 'chord') {
      path.arcTo(Rect.fromLTWH(0, 0, w, h), -math.pi * 0.75, math.pi * 1.5, false);
      path.close();
    } else {
      // blockArc or arc
      final outer = Rect.fromLTWH(0, 0, w, h);
      final inner = Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.6, height: h * 0.6);
      path.arcTo(outer, -math.pi, math.pi, false);
      path.arcTo(inner, 0, -math.pi, false);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _ArcPieceClipper oldClipper) => oldClipper.type != type;
}

class _TeardropClipper extends CustomClipper<Path> {
  const _TeardropClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, h);
    path.cubicTo(0, h * 0.7, 0, h * 0.25, w * 0.5, 0);
    path.cubicTo(w, h * 0.25, w, h * 0.7, w * 0.5, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FrameClipper extends CustomClipper<Path> {
  const _FrameClipper(this.type);
  final String type;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final border = math.min(w, h) * 0.15;
    if (type == 'corner') {
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, border);
      path.lineTo(border, border);
      path.lineTo(border, h);
      path.lineTo(0, h);
      path.close();
    } else if (type == 'halfFrame') {
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
      path.lineTo(w - border, h);
      path.lineTo(w - border, border);
      path.lineTo(0, border);
      path.close();
    } else {
      path.addRect(Rect.fromLTWH(0, 0, w, h));
      path.addRect(Rect.fromLTWH(border, border, w - border * 2, h - border * 2));
      path.fillType = PathFillType.evenOdd;
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _FrameClipper oldClipper) => oldClipper.type != type;
}

class _FoldedCornerClipper extends CustomClipper<Path> {
  const _FoldedCornerClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final fold = math.min(w, h) * 0.22;
    path.moveTo(0, 0);
    path.lineTo(w - fold, 0);
    path.lineTo(w, fold);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper(this.type);
  final String type;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final notch = w * 0.08;
    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w - notch, h * 0.5);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.lineTo(notch, h * 0.5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _RibbonClipper oldClipper) => oldClipper.type != type;
}

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper(this.type);
  final String type;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h * 0.25);
    path.cubicTo(w * 0.25, 0, w * 0.75, h * 0.5, w, h * 0.25);
    path.lineTo(w, h);
    path.cubicTo(w * 0.75, h * 0.75, w * 0.25, h, 0, h * 0.75);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) => oldClipper.type != type;
}

class _PlaqueClipper extends CustomClipper<Path> {
  const _PlaqueClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = math.min(w, h) * 0.18;
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w - r, r, w, r);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w - r, h - r, w - r, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(r, h - r, 0, h - r);
    path.lineTo(0, r);
    path.quadraticBezierTo(r, r, r, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CapsuleClipper extends CustomClipper<Path> {
  const _CapsuleClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = math.min(size.width, size.height) * 0.5;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    ));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Paints crisp vector borders along the exact clipper path.
class SlideShapeBorderPainter extends CustomPainter {
  const SlideShapeBorderPainter({
    required this.clipper,
    required this.borderColor,
    required this.borderWidth,
  });

  final CustomClipper<Path> clipper;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SlideShapeBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
