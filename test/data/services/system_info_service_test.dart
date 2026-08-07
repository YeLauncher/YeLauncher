import 'package:flutter_test/flutter_test.dart';
import 'package:yelauncher/data/services/system_info_service.dart';

void main() {
  late SystemInfoService systemInfoService;

  setUp(() {
    systemInfoService = SystemInfoService();
  });

  group('SystemInfoService', () {
    test('getTotalPhysicalMemoryMB returns a valid memory amount', () async {
      final memoryMB = await systemInfoService.getTotalPhysicalMemoryMB();
      
      // The fallback is 8192 MB (8GB). If it succeeds, it should also be > 0.
      // We just assert that it's a valid positive number to ensure it didn't crash
      // and either returned the fallback or the real system RAM.
      expect(memoryMB, greaterThan(0));
    });
  });
}
