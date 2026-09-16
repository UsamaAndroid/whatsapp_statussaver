enum MediaType { image, video }

class StatusItem {
  final String path;
  final String name;
  final MediaType type;
  final DateTime modified;

  const StatusItem({
    required this.path,
    required this.name,
    required this.type,
    required this.modified,
  });

  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;
}
