import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileService {
  Future<String> getAbsolutePath(String relativePath) async {
    final localPath = await _localPath;
    return p.join(localPath, relativePath);
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
