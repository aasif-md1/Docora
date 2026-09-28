import 'dart:ui';

/// Reading modes available in Docora's PDF viewer.
/// Modifies the color rendering of the document using GPU color matrices.
enum PdfReadingMode {
  normal('Normal', 'Standard display'),
  dark('Night Mode', 'Inverted dark colors for low-light reading'),
  sepia('Sepia', 'Warm eye-comfort amber tint'),
  grayscale('Grayscale', 'High contrast monochrome');

  const PdfReadingMode(this.label, this.description);
  final String label;
  final String description;

  /// Returns the 4x5 ColorFilter matrix for the given reading mode, or null for normal.
  List<double>? get colorMatrix {
    switch (this) {
      case PdfReadingMode.normal:
        return null;
      case PdfReadingMode.dark:
        return const <double>[
          -1.0, 0.0, 0.0, 0.0, 255.0, // R
          0.0, -1.0, 0.0, 0.0, 255.0, // G
          0.0, 0.0, -1.0, 0.0, 255.0, // B
          0.0, 0.0, 0.0, 1.0, 0.0, // A
        ];
      case PdfReadingMode.sepia:
        return const <double>[
          0.393, 0.769, 0.189, 0.0, 0.0, // R
          0.349, 0.686, 0.168, 0.0, 0.0, // G
          0.272, 0.534, 0.131, 0.0, 0.0, // B
          0.0, 0.0, 0.0, 1.0, 0.0, // A
        ];
      case PdfReadingMode.grayscale:
        return const <double>[
          0.2126, 0.7152, 0.0722, 0.0, 0.0, // R
          0.2126, 0.7152, 0.0722, 0.0, 0.0, // G
          0.2126, 0.7152, 0.0722, 0.0, 0.0, // B
          0.0, 0.0, 0.0, 1.0, 0.0, // A
        ];
    }
  }

  ColorFilter? get colorFilter {
    final matrix = colorMatrix;
    return matrix != null ? ColorFilter.matrix(matrix) : null;
  }
}

/// Page layout orientation mode for PDF viewer.
enum PdfLayoutMode {
  verticalContinuous('Continuous Scroll', 'Scroll smoothly top to bottom'),
  horizontalSingle('Single Page Flip', 'Slide one page horizontally at a time');

  const PdfLayoutMode(this.label, this.description);
  final String label;
  final String description;
}
