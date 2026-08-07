import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/ui/content/view_models/content_screen_viewmodel.dart';
import 'package:yelauncher/utilities/result.dart';

import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'content_screen_viewmodel_test.mocks.dart';

@GenerateMocks([ContentRepository, MinecraftRepository])
void main() {
  late MockContentRepository mockRepository;
  late MockMinecraftRepository mockMinecraftRepository;
  late ContentScreenViewModel viewModel;

  setUp(() {
    provideDummy<Result<List<ContentItem>>>(const Success([]));
    provideDummy<Result<List<MinecraftVersionModel>>>(const Success([]));
    mockRepository = MockContentRepository();
    mockMinecraftRepository = MockMinecraftRepository();
    
    when(mockMinecraftRepository.getVersions())
        .thenAnswer((_) async => const Success([]));

    viewModel = ContentScreenViewModel(
      contentRepository: mockRepository,
      minecraftRepository: mockMinecraftRepository,
    );
  });

  test('initial state is correct', () {
    expect(viewModel.items, isEmpty);
    expect(viewModel.isLoading, isTrue);
    expect(viewModel.projectType, 'mod');
    expect(viewModel.query, '');
  });

  test('search updates state with results', () async {
    final item = ContentItem(id: '1', slug: 'mod', title: 'Mod', description: 'Desc', projectType: 'mod');
    when(mockRepository.searchContent(
            query: '',
            projectType: 'mod',
            versions: [],
            modLoaders: [],
            categories: [],
            limit: 20,
            offset: 0,
            sortOrder: 'relevance'))
        .thenAnswer((_) async => Result.success([item]));

    await viewModel.search();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.items, [item]);
  });
}
