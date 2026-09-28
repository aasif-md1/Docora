/// Centralized route path constants for go_router.
/// All navigation calls must use these constants — never raw strings.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String files = '/files';
  static const String tools = '/tools';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String pdfViewer = '/viewer/pdf';
  static const String wordViewer = '/viewer/word';
  static const String excelViewer = '/viewer/excel';
  static const String pptViewer = '/viewer/ppt';
  static const String textViewer = '/viewer/text';
  static const String epubViewer = '/viewer/epub';
  static const String imageViewer = '/viewer/image';
  static const String archiveViewer = '/viewer/archive';
  static const String docxEditor = '/editor/docx';
  static const String xlsxEditor = '/editor/xlsx';
  static const String textEditor = '/editor/text';
  static const String scanner = '/scanner';
  static const String vault = '/vault';
  static const String recycleBin = '/recycle-bin';
  static const String collections = '/collections';
  static const String widgets = '/widgets';
  static const String componentGallery = '/dev/gallery';
  static const String imageToPdf = '/tools/image-to-pdf';
  static const String mergePdf = '/tools/merge';
  static const String splitPdf = '/tools/split-pdf';
  static const String watermarkPdf = '/tools/watermark';
  static const String compressPdf = '/tools/compress';
}
