import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../core/constants.dart';
import '../models/status_item.dart';

class MediaGridItem extends StatelessWidget {
  final StatusItem item;
  final bool showDownloadButton;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const MediaGridItem({
    super.key,
    required this.item,
    required this.onTap,
    this.showDownloadButton = false,
    this.isSaved = false,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Thumbnail(path: item.path, isVideo: item.isVideo),
              if (item.isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              if (showDownloadButton && onDownload != null)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: GestureDetector(
                    onTap: onDownload,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSaved
                            ? Colors.grey
                            : AppConstants.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSaved ? Icons.check : Icons.download,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String path;
  final bool isVideo;

  const _Thumbnail({required this.path, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    if (isVideo) {
      return _VideoThumbnail(path: path);
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _MediaPlaceholder(isVideo: false),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String path;

  const _VideoThumbnail({required this.path});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  static final Map<String, Uint8List> _cache = {};

  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final cached = _cache[widget.path];
    if (cached != null) {
      setState(() {
        _bytes = cached;
        _loading = false;
        _failed = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
      _bytes = null;
    });

    try {
      final data = await VideoThumbnail.thumbnailData(
        video: widget.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 60,
        timeMs: 500,
      );

      if (!mounted) return;

      if (data != null) {
        _cache[widget.path] = data;
        setState(() {
          _bytes = data;
          _loading = false;
        });
      } else {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConstants.primaryGreen,
            ),
          ),
        ),
      );
    }

    if (_failed || _bytes == null) {
      return const _MediaPlaceholder(isVideo: true);
    }

    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const _MediaPlaceholder(isVideo: true),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  final bool isVideo;

  const _MediaPlaceholder({required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        isVideo ? Icons.videocam : Icons.image,
        color: Colors.grey.shade500,
        size: 40,
      ),
    );
  }
}
