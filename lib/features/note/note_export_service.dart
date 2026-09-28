import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Thrown when the user refuses photo-library access.
class NotePermissionDeniedException implements Exception {
  const NotePermissionDeniedException();

  @override
  String toString() => 'Allow photo access in Settings to save notes.';
}

/// Renders the note canvas to a PNG and hands it to the gallery or WhatsApp.
class NoteExportService {
  static const MethodChannel _channel = MethodChannel('app.notes/whatsapp');

  /// Width of the exported image; with a 9:16 canvas this yields 1080x1920,
  /// the native WhatsApp Status size.
  static const double exportWidth = 1080;

  static const String _album = 'StatusSaver';

  /// Captures the [RepaintBoundary] attached to [boundaryKey] as PNG bytes.
  Future<Uint8List> capturePng(GlobalKey boundaryKey) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Note canvas is not ready yet.');
    }
    final pixelRatio = exportWidth / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode the note image.');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> saveToGallery(Uint8List png) async {
    if (!await Gal.hasAccess(toAlbum: true) &&
        !await Gal.requestAccess(toAlbum: true)) {
      throw const NotePermissionDeniedException();
    }
    await Gal.putImageBytes(png, name: _fileName(), album: _album);
  }

  /// Opens WhatsApp's send screen (where "My status" sits at the top) on
  /// Android, falling back to the system share sheet when WhatsApp isn't
  /// installed or on iOS.
  ///
  /// WhatsApp offers no public API to post to Status without the user's
  /// final tap, so this is as far as an app can take it.
  Future<void> shareToWhatsAppStatus(
    Uint8List png, {
    Rect? sharePositionOrigin,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName()}.png');
    await file.writeAsBytes(png, flush: true);

    if (Platform.isAndroid) {
      try {
        final sent = await _channel.invokeMethod<bool>(
          'shareImageToWhatsApp',
          {'path': file.path},
        );
        if (sent == true) return;
      } on PlatformException {
        // Fall through to the system share sheet.
      }
    }

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  String _fileName() => 'note_${DateTime.now().millisecondsSinceEpoch}';
}
