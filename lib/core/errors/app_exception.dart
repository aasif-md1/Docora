import 'package:equatable/equatable.dart';

/// Base class for all domain-level exceptions in Docora.
/// Use subclasses to express specific error categories.
sealed class AppException extends Equatable implements Exception {
  const AppException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() => '$runtimeType: $message';
}

/// File system errors — file not found, permission denied, I/O error
final class FileException extends AppException {
  const FileException({required super.message, super.cause});
}

/// Parse/render errors — corrupted or malformed document
final class ParseException extends AppException {
  const ParseException({required super.message, super.cause});
}

/// Database read/write errors
final class DatabaseException extends AppException {
  const DatabaseException({required super.message, super.cause});
}

/// Permission denied by the user or OS
final class PermissionException extends AppException {
  const PermissionException({required super.message, super.cause});
}

/// Encryption / decryption errors (vault)
final class SecurityException extends AppException {
  const SecurityException({required super.message, super.cause});
}

/// A feature is not yet implemented or not supported for this format
final class UnsupportedException extends AppException {
  const UnsupportedException({required super.message, super.cause});
}

/// Generic unexpected error — should be rare
final class UnknownException extends AppException {
  const UnknownException({required super.message, super.cause});
}
