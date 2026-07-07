import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:yelauncher/data/services/api/modrinth_client.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/utilities/result.dart';

import 'modrinth_client_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late ModrinthClient client;

  setUp(() {
    mockClient = MockClient();
    client = ModrinthClient(httpClient: mockClient);
  });

  test('searchContent returns items on success', () async {
    when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
      (_) async => http.Response('{"hits":[{"project_id":"1","slug":"test","title":"Test","description":"Desc","project_type":"mod"}]}', 200),
    );

    final result = await client.searchContent(query: 'test', projectType: 'mod');

    expect(result is Success, isTrue);
    if (result is Success<List<ContentItem>>) {
      expect(result.value.length, 1);
      expect(result.value.first.id, '1');
      expect(result.value.first.title, 'Test');
    }
  });

  test('searchContent returns failure on error', () async {
    when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
      (_) async => http.Response('Error', 500),
    );

    final result = await client.searchContent(query: 'test', projectType: 'mod');

    expect(result is Failure, isTrue);
  });
}
