import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/ models/character.dart';
import '../../../data/repository/character_repository.dart';

enum LoadStatus { idle, loading, success, empty, error }

class DirectoryProvider extends ChangeNotifier {
  final CharacterRepository repo;
  final Box cacheBox;

  DirectoryProvider(this.repo, this.cacheBox);

  final List<Character> _items = [];
  List<Character> get items => _query.isEmpty ? _items : _filtered;
  final List<Character> _filtered = [];

  LoadStatus status = LoadStatus.idle;
  String? errorMessage;
  bool hasNext = false;
  int _page = 1;

  // offline
  bool offlineMode = false;

  // search
  String _query = '';
  Timer? _debounce;

  Future<void> init() async {
    // try cached data first
    final cache = repo.readCache(cacheBox);
    if (cache.items.isNotEmpty) {
      _items
        ..clear()
        ..addAll(cache.items);
      hasNext = cache.hasNext;
      _page = cache.page;
      offlineMode = true; // will flip to false if network fetch succeeds
      status = LoadStatus.success;
      notifyListeners();
    }

    // then try fetching fresh page 1
    await refresh();
  }

  Future<void> refresh() async {
    status = LoadStatus.loading;
    errorMessage = null;
    offlineMode = false;
    notifyListeners();
    try {
      final (list, next) = await repo.getPage(1);
      _items
        ..clear()
        ..addAll(list);
      hasNext = next;
      _page = 1;
      status = _items.isEmpty ? LoadStatus.empty : LoadStatus.success;
      repo.writeCache(cacheBox, _items, _page, hasNext);
    } catch (e) {
      // fall back to whatever cache we have
      if (_items.isNotEmpty) {
        offlineMode = true;
        status = LoadStatus.success;
      } else {
        status = LoadStatus.error;
        errorMessage = 'Failed to load. Please try again.';
      }
    }
    _applySearch();
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasNext || status == LoadStatus.loading) return;
    status = LoadStatus.loading;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final (list, next) = await repo.getPage(nextPage);
      _items.addAll(list);
      hasNext = next;
      _page = nextPage;
      status = LoadStatus.success;
      repo.writeCache(cacheBox, _items, _page, hasNext);
    } catch (_) {
      status = LoadStatus.success; // keep current data; maybe show a toast in UI
    }
    _applySearch();
    notifyListeners();
  }

  void onSearchChanged(String q) {
    _query = q.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _applySearch();
      notifyListeners();
    });
  }

  void _applySearch() {
    if (_query.isEmpty) {
      _filtered.clear();
      return;
    }
    final q = _query.toLowerCase();
    _filtered
      ..clear()
      ..addAll(_items.where((c) =>
      c.name.toLowerCase().contains(q) ||
          c.species.toLowerCase().contains(q) ||
          c.status.toLowerCase().contains(q)));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
