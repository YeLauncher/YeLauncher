import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/ui/content/view_models/content_screen_viewmodel.dart';
import 'package:yelauncher/utilities/result.dart';

import 'content_screen_viewmodel_test.mocks.dart';

@GenerateMocks([ContentRepository])
void main() {
  late MockContentRepository mockRepository;
  late ContentScreenViewModel viewModel;

  setUp(() {
    provideDummy<Result<List<ContentItem>>>(const Success([]));
    mockRepository = MockContentRepository();
    viewModel = ContentScreenViewModel(contentRepository: mockRepository);
  });

  test('initial state is correct', () {
    expect(viewModel.items, isEmpty);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.projectType, 'mod');
    expect(viewModel.query, '');
  });

  test('search updates state with results', () async {
    final item = ContentItem(id: '1', slug: 'mod', title: 'Mod', description: 'Desc', projectType: 'mod');
    when(mockRepository.searchContent(query: '', projectType: 'mod', limit: 20, offset: 0))
        .thenAnswer((_) async => Result.success([item]));

    await viewModel.search();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.items, [item]);
  });
}
