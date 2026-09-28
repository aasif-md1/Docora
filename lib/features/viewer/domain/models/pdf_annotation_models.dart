import 'package:flutter/material.dart';

enum AnnotationTool {
  none,
  pen,
  highlighter,
  eraser,
  note,
  signature,
}

class StrokePoint {
  const StrokePoint(this.dx, this.dy);
  final double dx;
  final double dy;

  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};
  factory StrokePoint.fromJson(Map<String, dynamic> json) =>
      StrokePoint((json['dx'] as num).toDouble(), (json['dy'] as num).toDouble());
}

class PdfStroke {
  PdfStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.isHighlighter,
  });

  final List<StrokePoint> points;
  final Color color;
  final double width;
  final bool isHighlighter;

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'color': color.value,
        'width': width,
        'isHighlighter': isHighlighter,
      };

  factory PdfStroke.fromJson(Map<String, dynamic> json) => PdfStroke(
        points: (json['points'] as List)
            .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        color: Color(json['color'] as int),
        width: (json['width'] as num).toDouble(),
        isHighlighter: json['isHighlighter'] as bool? ?? false,
      );
}

class PdfTextAnnotation {
  PdfTextAnnotation({
    required this.id,
    required this.page,
    required this.xRatio,
    required this.yRatio,
    required this.content,
    required this.color,
  });

  final String id;
  final int page;
  final double xRatio;
  final double yRatio;
  final String content;
  final Color color;

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'xRatio': xRatio,
        'yRatio': yRatio,
        'content': content,
        'color': color.value,
      };

  factory PdfTextAnnotation.fromJson(Map<String, dynamic> json) =>
      PdfTextAnnotation(
        id: json['id'] as String,
        page: json['page'] as int,
        xRatio: (json['xRatio'] as num).toDouble(),
        yRatio: (json['yRatio'] as num).toDouble(),
        content: json['content'] as String,
        color: Color(json['color'] as int),
      );
}

class PdfSignatureAnnotation {
  PdfSignatureAnnotation({
    required this.id,
    required this.page,
    required this.xRatio,
    required this.yRatio,
    required this.strokes,
  });

  final String id;
  final int page;
  final double xRatio;
  final double yRatio;
  final List<PdfStroke> strokes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'xRatio': xRatio,
        'yRatio': yRatio,
        'strokes': strokes.map((s) => s.toJson()).toList(),
      };

  factory PdfSignatureAnnotation.fromJson(Map<String, dynamic> json) =>
      PdfSignatureAnnotation(
        id: json['id'] as String,
        page: json['page'] as int,
        xRatio: (json['xRatio'] as num).toDouble(),
        yRatio: (json['yRatio'] as num).toDouble(),
        strokes: (json['strokes'] as List)
            .map((s) => PdfStroke.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
