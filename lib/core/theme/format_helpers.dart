import 'package:docora/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Supported document categories and formats in Docora
enum DocumentFormat {
  pdf('PDF', AppColors.filePdf, LucideIcons.file_text),
  word('Word', AppColors.fileWord, LucideIcons.file_pen),
  excel('Excel', AppColors.fileExcel, LucideIcons.file_spreadsheet),
  ppt('PowerPoint', AppColors.filePpt, LucideIcons.file_play),
  image('Image', AppColors.fileImage, LucideIcons.file_image),
  text('Text', AppColors.fileText, LucideIcons.file_text),
  code('Code', Color(0xFF10B981), LucideIcons.file_code),
  archive('Archive', AppColors.fileArchive, LucideIcons.file_archive),
  audio('Audio', Color(0xFFEC4899), LucideIcons.file_music),
  video('Video', Color(0xFF06B6D4), LucideIcons.video),
  epub('EPUB', AppColors.fileEpub, LucideIcons.book_open),
  other('Document', Color(0xFF6B7280), LucideIcons.file);

  const DocumentFormat(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static DocumentFormat fromExtension(String ext) {
    final clean = ext.toLowerCase().replaceAll('.', '').trim();
    switch (clean) {
      case 'pdf':
        return DocumentFormat.pdf;
      case 'doc':
      case 'docx':
      case 'rtf':
      case 'odt':
        return DocumentFormat.word;
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'tsv':
      case 'ods':
        return DocumentFormat.excel;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return DocumentFormat.ppt;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
      case 'gif':
      case 'bmp':
      case 'heic':
      case 'svg':
        return DocumentFormat.image;
      case 'txt':
      case 'log':
      case 'md':
      case 'markdown':
        return DocumentFormat.text;
      case 'dart':
      case 'js':
      case 'ts':
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'html':
      case 'css':
      case 'py':
      case 'java':
      case 'kt':
      case 'cpp':
      case 'c':
      case 'sh':
        return DocumentFormat.code;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return DocumentFormat.archive;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'flac':
        return DocumentFormat.audio;
      case 'mp4':
      case 'mkv':
      case 'webm':
      case 'avi':
      case 'mov':
        return DocumentFormat.video;
      case 'epub':
      case 'mobi':
        return DocumentFormat.epub;
      default:
        return DocumentFormat.other;
    }
  }

  static DocumentFormat fromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'pdf':
        return DocumentFormat.pdf;
      case 'word':
        return DocumentFormat.word;
      case 'excel':
        return DocumentFormat.excel;
      case 'ppt':
        return DocumentFormat.ppt;
      case 'image':
      case 'images':
        return DocumentFormat.image;
      case 'text':
        return DocumentFormat.text;
      case 'code':
        return DocumentFormat.code;
      case 'archive':
      case 'archives':
        return DocumentFormat.archive;
      case 'audio':
        return DocumentFormat.audio;
      case 'video':
        return DocumentFormat.video;
      case 'epub':
        return DocumentFormat.epub;
      default:
        return DocumentFormat.other;
    }
  }
}
