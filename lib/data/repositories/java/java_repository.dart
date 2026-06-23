import 'package:yelauncher/utilities/result.dart';

abstract class JavaRepository {
  Future<Result<String>> getJavaExecutablePath(int version);
  Future<Result<void>> install(int version, {void Function(double)? onProgress});
  Future<Result<bool>> isInstalled(int version);
}
