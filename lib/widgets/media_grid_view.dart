import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/status_item.dart';
import '../services/permission_service.dart';
import '../services/status_folder_service.dart';
import '../services/status_service.dart';
import 'empty_state_widget.dart';
import 'media_grid_item.dart';
import 'usage_guide_dialog.dart';

class MediaGridView extends StatefulWidget {
  final bool isVideoTab;
  final bool isSavedTab;
  final StatusService statusService;
  final void Function(StatusItem item, List<StatusItem> allItems)? onItemTap;
  final VoidCallback? onDataChanged;

  const MediaGridView({
    super.key,
    required this.isVideoTab,
    required this.isSavedTab,
    required this.statusService,
    this.onItemTap,
    this.onDataChanged,
  });

  @override
  State<MediaGridView> createState() => _MediaGridViewState();
}

class _MediaGridViewState extends State<MediaGridView>
    with AutomaticKeepAliveClientMixin {
  final PermissionService _permissionService = PermissionService();
  final StatusFolderService _folderService = StatusFolderService();

  List<StatusItem> _items = [];
  final Map<String, bool> _savedMap = {};
  bool _loading = true;
  bool _needsFolderAccess = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);

    if (!widget.isSavedTab) {
      _needsFolderAccess = await widget.statusService.needsFolderAccess();
    }

    final items = widget.isSavedTab
        ? await widget.statusService.getSavedStatuses(videos: widget.isVideoTab)
        : await widget.statusService.getStatuses(videos: widget.isVideoTab);

    if (!widget.isSavedTab) {
      for (final item in items) {
        _savedMap[item.path] = await widget.statusService.isAlreadySaved(item);
      }
    }

    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _requestFolderAccess() async {
    await _permissionService.requestMediaPermission();

    // Media permission alone is enough on most devices.
    if (!await widget.statusService.needsFolderAccess()) {
      if (mounted) await _loadItems();
      return;
    }

    final result = await _folderService.requestAccess();
    if (!mounted) return;

    if (result == FolderAccessResult.wrongFolder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That folder holds no statuses. Open the folder the picker starts '
            'in and tap "Use this folder".',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } else if (result == FolderAccessResult.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the folder picker.')),
      );
    }

    await _loadItems();
  }

  Future<void> _downloadItem(StatusItem item) async {
    final result = await widget.statusService.saveStatus(item);
    if (result != null && mounted) {
      setState(() => _savedMap[item.path] = true);
      widget.onDataChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${item.name}'),
          backgroundColor: AppConstants.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save status')),
      );
    }
  }

  void refresh() => _loadItems();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryGreen),
      );
    }

    if (_items.isEmpty) {
      if (!widget.isSavedTab && _needsFolderAccess) {
        return EmptyStateWidget(
          message:
              'Allow access to your status folder so the app can show the '
              'statuses you have viewed.',
          onHowToUse: () => UsageGuideDialog.show(context),
          actionLabel: 'Allow folder access',
          onAction: _requestFolderAccess,
        );
      }

      final message = widget.isVideoTab
          ? 'No videos available now.\nOpen Updates in your messaging app, watch a status fully, then pull down to refresh.'
          : 'No images available now.\nOpen Updates in your messaging app, watch a status fully, then pull down to refresh.';
      return EmptyStateWidget(
        message: message,
        onHowToUse: () => UsageGuideDialog.show(context),
        actionLabel: widget.isSavedTab ? null : 'Refresh',
        onAction: widget.isSavedTab ? null : _loadItems,
      );
    }

    return RefreshIndicator(
      color: AppConstants.primaryGreen,
      onRefresh: _loadItems,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return MediaGridItem(
            item: item,
            showDownloadButton: !widget.isSavedTab,
            isSaved: _savedMap[item.path] ?? false,
            onTap: () => widget.onItemTap?.call(item, _items),
            onDownload: () => _downloadItem(item),
          );
        },
      ),
    );
  }
}
