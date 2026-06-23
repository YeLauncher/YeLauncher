enum DownloadStatus { pending, downloading, finished, failed }

class DownloadModel {
  final String url;
  final String path;
  final String sha1;
  final int? expectedSize;

  DownloadModel({
    required this.url,
    required this.path,
    required this.sha1,
    this.expectedSize
  });
}
