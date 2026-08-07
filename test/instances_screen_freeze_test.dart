import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instances_screen.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:mockito/mockito.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class MockInstanceRepository extends Mock implements InstanceRepository {
  @override
  Future<List<InstanceModel>> getInstances() async {
    return [];
  }
}
class MockMinecraftRepository extends Mock implements MinecraftRepository {}
class MockDownloadService extends Mock implements DownloadService {}
class MockJavaRepository extends Mock implements JavaRepository {}

void main() {
  testWidgets('InstancesScreen does not freeze', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    
    final mockInstanceRepo = MockInstanceRepository();
    final viewModel = InstanceScreenViewModel(instanceRepository: mockInstanceRepo);
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MinecraftRepository>.value(value: MockMinecraftRepository()),
          Provider<InstanceRepository>.value(value: mockInstanceRepo),
          Provider<DownloadService>.value(value: MockDownloadService()),
          Provider<JavaRepository>.value(value: MockJavaRepository()),
          Provider<List<ModLoaderRepository>>.value(value: []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InstancesScreen(viewModel: viewModel),
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    expect(find.byType(InstancesScreen), findsOneWidget);
  });
}
