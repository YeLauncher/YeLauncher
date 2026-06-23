import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/utilities/result.dart';

class ContentScreenViewModel extends ChangeNotifier {
  final ContentRepository _contentRepository;

  ContentScreenViewModel({required ContentRepository contentRepository})
      : _contentRepository = contentRepository;

  List<ContentItem> items = [];
  bool isLoading = false;
  bool isLoadingMore = false; // Tracks pagination loading state
  bool hasMoreData = true;     // Flag to prevent useless API calls

  String projectType = 'mod';
  String query = '';

  int _offset = 0;
  final int _limit = 20;

  // Initial fresh search/filter change
  Future<void> search() async {
    isLoading = true;
    isLoadingMore = false;
    hasMoreData = true;
    _offset = 0;
    items = [];
    notifyListeners();

    final result = await _contentRepository.searchContent(
      query: query,
      projectType: projectType,
      limit: _limit,
      offset: _offset,
    );

    if (result is Success<List<ContentItem>>) {
      items = result.value;
      // If retrieved items are less than the limit, no more data is available
      if (result.value.length < _limit) {
        hasMoreData = false;
      }
    } else {
      items = [];
      hasMoreData = false;
    }

    isLoading = false;
    notifyListeners();
  }

  // Requests the next batch of elements when scrolling down
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMoreData) return;

    isLoadingMore = true;
    notifyListeners();

    _offset = items.length; // Dynamic update based on currently fetched items

    final result = await _contentRepository.searchContent(
      query: query,
      projectType: projectType,
      limit: _limit,
      offset: _offset,
    );

    if (result is Success<List<ContentItem>>) {
      final newItems = result.value;
      items.addAll(newItems);

      if (newItems.length < _limit) {
        hasMoreData = false;
      }
    } else {
      hasMoreData = false;
    }

    isLoadingMore = false;
    notifyListeners();
  }

  void setProjectType(String type) {
    if (projectType != type) {
      projectType = type;
      search();
    }
  }

  void setQuery(String newQuery) {
    if (query != newQuery) {
      query = newQuery;
      search();
    }
  }
}