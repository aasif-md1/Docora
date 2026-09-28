import 'package:path/path.dart' as p;

/// Detects programming and markup language from file extension.
class LanguageDetector {
  const LanguageDetector._();

  static const Map<String, ({String highlightLang, String label, bool isCode, bool isMarkdown})>
      _extensionMap = {
    // Markdown
    'md': (highlightLang: 'markdown', label: 'Markdown', isCode: false, isMarkdown: true),
    'markdown': (highlightLang: 'markdown', label: 'Markdown', isCode: false, isMarkdown: true),

    // Plain Text & Logs
    'txt': (highlightLang: 'plaintext', label: 'Plain Text', isCode: false, isMarkdown: false),
    'log': (highlightLang: 'plaintext', label: 'Log File', isCode: false, isMarkdown: false),
    'env': (highlightLang: 'bash', label: 'Environment Config', isCode: true, isMarkdown: false),

    // Web & Scripts
    'dart': (highlightLang: 'dart', label: 'Dart', isCode: true, isMarkdown: false),
    'js': (highlightLang: 'javascript', label: 'JavaScript', isCode: true, isMarkdown: false),
    'mjs': (highlightLang: 'javascript', label: 'JavaScript', isCode: true, isMarkdown: false),
    'ts': (highlightLang: 'typescript', label: 'TypeScript', isCode: true, isMarkdown: false),
    'jsx': (highlightLang: 'javascript', label: 'React JSX', isCode: true, isMarkdown: false),
    'tsx': (highlightLang: 'typescript', label: 'React TSX', isCode: true, isMarkdown: false),
    'html': (highlightLang: 'xml', label: 'HTML', isCode: true, isMarkdown: false),
    'htm': (highlightLang: 'xml', label: 'HTML', isCode: true, isMarkdown: false),
    'css': (highlightLang: 'css', label: 'CSS', isCode: true, isMarkdown: false),
    'scss': (highlightLang: 'scss', label: 'SCSS', isCode: true, isMarkdown: false),

    // Data & Config
    'json': (highlightLang: 'json', label: 'JSON', isCode: true, isMarkdown: false),
    'xml': (highlightLang: 'xml', label: 'XML', isCode: true, isMarkdown: false),
    'yaml': (highlightLang: 'yaml', label: 'YAML', isCode: true, isMarkdown: false),
    'yml': (highlightLang: 'yaml', label: 'YAML', isCode: true, isMarkdown: false),
    'ini': (highlightLang: 'ini', label: 'INI Config', isCode: true, isMarkdown: false),
    'toml': (highlightLang: 'ini', label: 'TOML', isCode: true, isMarkdown: false),
    'sql': (highlightLang: 'sql', label: 'SQL', isCode: true, isMarkdown: false),

    // Backend & Systems
    'py': (highlightLang: 'python', label: 'Python', isCode: true, isMarkdown: false),
    'java': (highlightLang: 'java', label: 'Java', isCode: true, isMarkdown: false),
    'kt': (highlightLang: 'kotlin', label: 'Kotlin', isCode: true, isMarkdown: false),
    'c': (highlightLang: 'c', label: 'C', isCode: true, isMarkdown: false),
    'cpp': (highlightLang: 'cpp', label: 'C++', isCode: true, isMarkdown: false),
    'h': (highlightLang: 'c', label: 'C Header', isCode: true, isMarkdown: false),
    'hpp': (highlightLang: 'cpp', label: 'C++ Header', isCode: true, isMarkdown: false),
    'cs': (highlightLang: 'cs', label: 'C#', isCode: true, isMarkdown: false),
    'go': (highlightLang: 'go', label: 'Go', isCode: true, isMarkdown: false),
    'rs': (highlightLang: 'rust', label: 'Rust', isCode: true, isMarkdown: false),
    'php': (highlightLang: 'php', label: 'PHP', isCode: true, isMarkdown: false),
    'rb': (highlightLang: 'ruby', label: 'Ruby', isCode: true, isMarkdown: false),
    'swift': (highlightLang: 'swift', label: 'Swift', isCode: true, isMarkdown: false),

    // Shell & Scripts
    'sh': (highlightLang: 'bash', label: 'Shell Script', isCode: true, isMarkdown: false),
    'bash': (highlightLang: 'bash', label: 'Bash Script', isCode: true, isMarkdown: false),
    'bat': (highlightLang: 'dos', label: 'Batch Script', isCode: true, isMarkdown: false),
    'ps1': (highlightLang: 'powershell', label: 'PowerShell', isCode: true, isMarkdown: false),
  };

  /// Returns true if the file extension or filename is supported as text, code, or markdown.
  static bool isSupported(String filePath) {
    final fileName = p.basename(filePath).toLowerCase();
    if (fileName == 'readme' || fileName.startsWith('readme.') ||
        fileName == 'license' || fileName == 'changelog' ||
        fileName == 'dockerfile' || fileName == 'makefile') {
      return true;
    }
    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
    return _extensionMap.containsKey(ext);
  }

  /// Returns language info for a file path or extension.
  static ({String highlightLang, String label, bool isCode, bool isMarkdown}) detect(
      String filePath) {
    final fileName = p.basename(filePath).toLowerCase();
    if (fileName == 'readme' || fileName.startsWith('readme.')) {
      return (highlightLang: 'markdown', label: 'Markdown', isCode: false, isMarkdown: true);
    }
    if (fileName == 'license' || fileName == 'changelog' || fileName == 'contributing') {
      return (highlightLang: 'plaintext', label: 'Plain Text', isCode: false, isMarkdown: false);
    }
    if (fileName == 'dockerfile') {
      return (highlightLang: 'dockerfile', label: 'Dockerfile', isCode: true, isMarkdown: false);
    }
    if (fileName == 'makefile') {
      return (highlightLang: 'makefile', label: 'Makefile', isCode: true, isMarkdown: false);
    }
    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
    return _extensionMap[ext] ??
        (highlightLang: 'plaintext', label: 'Plain Text', isCode: false, isMarkdown: false);
  }
}

/// In-memory representation of a loaded text or source code file.
class TextDocument {
  const TextDocument({
    required this.filePath,
    required this.fileName,
    required this.content,
    required this.fileSizeBytes,
    required this.encodingName,
    required this.highlightLanguage,
    required this.languageLabel,
    required this.isCode,
    required this.isMarkdown,
    required this.lines,
  });

  factory TextDocument.empty({
    String filePath = '',
    String fileName = '',
  }) =>
      TextDocument(
        filePath: filePath,
        fileName: fileName,
        content: '',
        fileSizeBytes: 0,
        encodingName: 'UTF-8',
        highlightLanguage: 'plaintext',
        languageLabel: 'Plain Text',
        isCode: false,
        isMarkdown: false,
        lines: const [],
      );

  final String filePath;
  final String fileName;
  final String content;
  final int fileSizeBytes;
  final String encodingName;
  final String highlightLanguage;
  final String languageLabel;
  final bool isCode;
  final bool isMarkdown;
  final List<String> lines;

  int get lineCount => lines.length;

  int get characterCount => content.length;

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return RegExp(r'\S+').allMatches(content).length;
  }
}
