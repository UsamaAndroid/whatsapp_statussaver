import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/status_item.dart';
import '../services/status_service.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/media_grid_view.dart';
import 'status_preview_screen.dart';

class SavedTabScreen extends StatefulWidget {
  final StatusService statusService;
  final VoidCallback onShareApp;
  final VoidCallback onSendFeedback;
  final bool showBackButton;

  const SavedTabScreen({
    super.key,
    required this.statusService,
    required this.onShareApp,
    required this.onSendFeedback,
    this.showBackButton = false,
  });

  @override
  State<SavedTabScreen> createState() => SavedTabScreenState();
}

class SavedTabScreenState extends State<SavedTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<State<MediaGridView>> _imagesKey = GlobalKey();
  final GlobalKey<State<MediaGridView>> _videosKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void refresh() {
    (_imagesKey.currentState as dynamic)?.refresh();
    (_videosKey.currentState as dynamic)?.refresh();
  }

  void _openPreview(StatusItem item, List<StatusItem> allItems) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatusPreviewScreen(
          item: item,
          allItems: allItems,
          statusService: widget.statusService,
          isFromSaved: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        showBackButton: widget.showBackButton,
        onShareApp: widget.onShareApp,
        onSendFeedback: widget.onSendFeedback,
      ),
      body: Column(
        children: [
          Material(
            color: AppConstants.primaryGreen,
            elevation: 2,
            shadowColor: Colors.black38,
            child: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              tabs: const [
                Tab(text: 'IMAGES'),
                Tab(text: 'VIDEOS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MediaGridView(
                  key: _imagesKey,
                  isVideoTab: false,
                  isSavedTab: true,
                  statusService: widget.statusService,
                  onItemTap: _openPreview,
                ),
                MediaGridView(
                  key: _videosKey,
                  isVideoTab: true,
                  isSavedTab: true,
                  statusService: widget.statusService,
                  onItemTap: _openPreview,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
