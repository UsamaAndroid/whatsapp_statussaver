import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'note_backgrounds.dart';
import 'note_export_service.dart';

enum _ExportAction { save, share }

/// RedNote-style text note: type, pick a background, then save the 1080x1920
/// image to the gallery or share it to WhatsApp Status.
class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  /// Fixed logical canvas size. The canvas is scaled to fit with a FittedBox,
  /// so the exported image always matches the preview.
  static const Size _canvasSize = Size(360, 640);
  static const int _maxLength = 400;
  static const Color _whatsAppGreen = Color(0xFF25D366);
  static const EdgeInsets _textPadding =
      EdgeInsets.symmetric(horizontal: 28, vertical: 48);

  final _exportService = NoteExportService();
  final _canvasKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  int _backgroundIndex = 0;
  TextAlign _textAlign = TextAlign.center;
  _ExportAction? _busy;

  /// While true the TextField is swapped for a plain Text so no cursor,
  /// selection handles or hint end up in the exported image.
  bool _capturing = false;

  NoteBackground get _background => NoteBackground.all[_backgroundIndex];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  static const double _minFontSize = 15;
  static const double _maxFontSize = 64;

  /// Largest font size (in whole points) at which the current text still fits
  /// inside the canvas — a few words fill the note, and the size shrinks
  /// smoothly as the text grows.
  String? _fitText;
  TextScaler? _fitScaler;
  double _fitSize = 34;

  double get _fontSize {
    final text = _controller.text;
    final textScaler = MediaQuery.textScalerOf(context);
    if (text == _fitText && textScaler == _fitScaler) return _fitSize;
    _fitText = text;
    _fitScaler = textScaler;
    return _fitSize = _computeFontSize(text, textScaler);
  }

  double _computeFontSize(String text, TextScaler textScaler) {
    if (text.trim().isEmpty) return 34;

    final maxWidth = _canvasSize.width - _textPadding.horizontal;
    final maxHeight = _canvasSize.height - _textPadding.vertical;

    bool fits(double size) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: _styleFor(size)),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: maxWidth);
      final ok = painter.height <= maxHeight && !painter.didExceedMaxLines;
      painter.dispose();
      return ok;
    }

    var low = _minFontSize.toInt();
    var high = _maxFontSize.toInt();
    if (!fits(low.toDouble())) return _minFontSize;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (fits(mid.toDouble())) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low.toDouble();
  }

  TextStyle _styleFor(double fontSize) => TextStyle(
        color: _background.textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        height: 1.35,
      );

  TextStyle get _textStyle => _styleFor(_fontSize);

  void _toggleAlign() {
    setState(() {
      _textAlign =
          _textAlign == TextAlign.center ? TextAlign.left : TextAlign.center;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Rect? _shareOrigin() {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _export(_ExportAction action) async {
    if (_busy != null) return;
    if (_controller.text.trim().isEmpty) {
      _showMessage('Type your note first.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = action;
      _capturing = true;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;
      final png = await _exportService.capturePng(_canvasKey);
      if (mounted) setState(() => _capturing = false);

      switch (action) {
        case _ExportAction.save:
          await _exportService.saveToGallery(png);
          if (mounted) _showMessage('Saved to gallery');
        case _ExportAction.share:
          await _exportService.shareToWhatsAppStatus(
            png,
            sharePositionOrigin: _shareOrigin(),
          );
      }
    } on NotePermissionDeniedException catch (e) {
      if (mounted) _showMessage(e.toString());
    } catch (e) {
      if (mounted) _showMessage('Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = null;
          _capturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.black,
        ),
        title: const Text('Create note'),
        actions: [
          IconButton(
            tooltip:
                _textAlign == TextAlign.center ? 'Align left' : 'Align center',
            icon: Icon(
              _textAlign == TextAlign.center
                  ? Icons.format_align_center
                  : Icons.format_align_left,
            ),
            onPressed: _toggleAlign,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Center(
                  child: FittedBox(
                    // Rounded corners on screen only — the clip sits outside
                    // the RepaintBoundary, so the export keeps square corners.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _buildCanvas(),
                    ),
                  ),
                ),
              ),
            ),
            _buildSwatches(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return RepaintBoundary(
      key: _canvasKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: _canvasSize.width,
          height: _canvasSize.height,
          decoration: _background.decoration,
          padding: _textPadding,
          alignment: Alignment.center,
          child: _capturing ? _buildStaticText() : _buildTextField(),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      maxLines: null,
      maxLength: _maxLength,
      keyboardType: TextInputType.multiline,
      textAlign: _textAlign,
      style: _textStyle,
      cursorColor: _background.textColor,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration.collapsed(
        hintText: 'Type your note…',
        hintStyle: _textStyle.copyWith(
          color: _background.textColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildStaticText() {
    return SizedBox(
      width: double.infinity,
      child: Text(
        _controller.text,
        textAlign: _textAlign,
        style: _textStyle,
      ),
    );
  }

  Widget _buildSwatches() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: NoteBackground.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final selected = index == _backgroundIndex;
          return GestureDetector(
            onTap: () => setState(() => _backgroundIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: NoteBackground.all[index].decoration.copyWith(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 3.5 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions() {
    final busy = _busy != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : () => _export(_ExportAction.save),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: busy ? Colors.white24 : Colors.white54),
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Save to gallery'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              key: _shareButtonKey,
              onPressed: busy ? null : () => _export(_ExportAction.share),
              style: FilledButton.styleFrom(
                backgroundColor: _whatsAppGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _whatsAppGreen.withOpacity(0.5),
                disabledForegroundColor: Colors.white70,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: _busy == _ExportAction.share
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: const Text('Share to Status'),
            ),
          ),
        ],
      ),
    );
  }
}
