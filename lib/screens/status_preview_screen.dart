import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../core/constants.dart';
import '../models/status_item.dart';
import '../services/status_service.dart';

class StatusPreviewScreen extends StatefulWidget {
  final StatusItem item;
  final List<StatusItem> allItems;
  final StatusService statusService;
  final bool isFromSaved;

  const StatusPreviewScreen({
    super.key,
    required this.item,
    required this.allItems,
    required this.statusService,
    this.isFromSaved = false,
  });

  @override
  State<StatusPreviewScreen> createState() => _StatusPreviewScreenState();
}

class _StatusPreviewScreenState extends State<StatusPreviewScreen> {
  late StatusItem _currentItem;
  late PageController _pageController;
  VideoPlayerController? _videoController;
  bool _isSaved = false;
  bool _checkingSaved = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    final initialIndex = widget.allItems.indexWhere(
      (i) => i.path == widget.item.path,
    );
    _pageController = PageController(
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );
    _checkSavedStatus();
    if (_currentItem.isVideo) {
      _initVideo(_currentItem.path);
    }
  }

  Future<void> _checkSavedStatus() async {
    if (widget.isFromSaved) {
      setState(() {
        _isSaved = true;
        _checkingSaved = false;
      });
      return;
    }
    final saved = await widget.statusService.isAlreadySaved(_currentItem);
    if (mounted) {
      setState(() {
        _isSaved = saved;
        _checkingSaved = false;
      });
    }
  }

  Future<void> _initVideo(String path) async {
    await _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    if (mounted) {
      setState(() {});
      _videoController!.setLooping(true);
      _videoController!.play();
    }
  }

  Future<void> _onPageChanged(int index) async {
    final item = widget.allItems[index];
    setState(() {
      _currentItem = item;
      _checkingSaved = true;
    });

    if (item.isVideo) {
      await _initVideo(item.path);
    } else {
      await _videoController?.pause();
      await _videoController?.dispose();
      _videoController = null;
      if (mounted) setState(() {});
    }

    if (!widget.isFromSaved) {
      final saved = await widget.statusService.isAlreadySaved(item);
      if (mounted) {
        setState(() {
          _isSaved = saved;
          _checkingSaved = false;
        });
      }
    } else {
      setState(() => _checkingSaved = false);
    }
  }

  Future<void> _saveStatus() async {
    if (_isSaved || _saving) return;
    setState(() => _saving = true);

    final result = await widget.statusService.saveStatus(_currentItem);
    if (mounted) {
      setState(() {
        _saving = false;
        _isSaved = result != null;
      });
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status saved successfully'),
            backgroundColor: AppConstants.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _shareStatus() async {
    await Share.shareXFiles(
      [XFile(_currentItem.path)],
      text: 'Shared via ${AppConstants.appName}',
    );
  }

  Future<void> _repostStatus() async {
    await Share.shareXFiles(
      [XFile(_currentItem.path)],
      text: 'Check out this status!',
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.isFromSaved ? 'Saved media' : 'Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.allItems.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final item = widget.allItems[index];
              return _MediaContent(
                item: item,
                videoController:
                    item.path == _currentItem.path ? _videoController : null,
              );
            },
          ),
          if (!_checkingSaved && _isSaved && !widget.isFromSaved)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_done,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Already exist',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.reply_all,
                label: 'Repost',
                onTap: _repostStatus,
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: _shareStatus,
              ),
              _ActionButton(
                icon: _isSaved ? Icons.check_circle : Icons.download,
                label: _isSaved ? 'Saved' : 'Save',
                onTap: _isSaved ? null : _saveStatus,
                isLoading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaContent extends StatelessWidget {
  final StatusItem item;
  final VideoPlayerController? videoController;

  const _MediaContent({required this.item, this.videoController});

  @override
  Widget build(BuildContext context) {
    if (item.isVideo && videoController != null) {
      if (!videoController!.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: AppConstants.primaryGreen),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child: VideoPlayer(videoController!),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: Image.file(
          File(item.path),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 64,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
