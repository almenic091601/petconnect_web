import 'dart:async';

/// Fallback printing implementation for non-web platforms.
/// The web implementation is provided by `printing_web.dart` via conditional import.
Future<void> printHtml(String html) async {
  // On non-web platforms, printing via window.print isn't available.
  // For now, throw to indicate unsupported.
  throw UnsupportedError('Printing HTML is only implemented for web builds.');
}
