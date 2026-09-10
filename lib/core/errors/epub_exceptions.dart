/// Base exception class for all EPUB processing errors.
class EpubException implements Exception {
  final String message;
  final dynamic cause;

  const EpubException(this.message, [this.cause]);

  @override
  String toString() =>
      cause != null ? 'EpubException: $message (Caused by: $cause)' : 'EpubException: $message';
}

/// Thrown when the EPUB file is missing, empty, or unreadable.
class EpubFileNotFoundException extends EpubException {
  const EpubFileNotFoundException(super.message, [super.cause]);
}

/// Thrown when the archive is not a valid ZIP file or is corrupted.
class EpubInvalidArchiveException extends EpubException {
  const EpubInvalidArchiveException(super.message, [super.cause]);
}

/// Thrown when META-INF/container.xml is missing from the EPUB archive.
class EpubContainerNotFoundException extends EpubException {
  const EpubContainerNotFoundException([
    super.message = 'META-INF/container.xml not found in EPUB archive',
    super.cause,
  ]);
}

/// Thrown when META-INF/container.xml cannot be parsed or lacks rootfile info.
class EpubInvalidContainerException extends EpubException {
  const EpubInvalidContainerException(super.message, [super.cause]);
}

/// Thrown when the OPF content package document is missing or invalid.
class EpubOpfException extends EpubException {
  const EpubOpfException(super.message, [super.cause]);
}

/// Thrown when parsing XHTML chapters or content elements fails.
class EpubContentParseException extends EpubException {
  const EpubContentParseException(super.message, [super.cause]);
}
