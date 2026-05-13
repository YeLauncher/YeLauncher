enum DownloadStatus { pending, downloading, finished, failed }

class DownloadModel {
  final String url;
  final String path;
  final String sha1;
  final int expectedSize;
  int downloadedSize;
  DownloadStatus status;
  final String? tag;

  DownloadModel({
    required this.url,
    required this.path,
    required this.sha1,
    this.expectedSize = 0,
    this.downloadedSize = 0,
    this.status = DownloadStatus.pending,
    this.tag,
  });
}
