import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/ models/character.dart';
import '../../../data/repository/character_repository.dart';

sealed class LoadStatus {
  const LoadStatus();
}

class Loading extends LoadStatus {
  const Loading();
}

class Success extends LoadStatus {
  const Success();
}

class Empty extends LoadStatus {
  const Empty();
}

class Error extends LoadStatus {
  final String message;
  const Error(this.message);
}

class DirectoryProvider with ChangeNotifier {
  final CharacterRepository repo;
  final Box cacheBox;
  final Box favoritesBox;
  final Connectivity connectivity;

  DirectoryProvider({
    required this.repo,
    required this.cacheBox,
    required this.favoritesBox,
    required this.connectivity,
  });

  List<Character> _allItems = [];
  List<Character> get items => _allItems;
  LoadStatus _status = const Loading();
  LoadStatus get status => _status;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _offlineMode = false;
  bool get offlineMode => _offlineMode;
  int _currentPage = 1;
  bool _hasNext = true;
  String _query = '';
  Set<int> _favorites = {};
  Set<int> get favorites => _favorites;
  bool _isLoadingMore = false;

  final _debouncer = Debouncer<String>(const Duration(milliseconds: 500), initialValue: '');

  Future<void> init() async {
    _status = const Loading();
    notifyListeners();
    try {
      await _checkConnectivity();
      if (_offlineMode) {
        _loadCache();
      } else {
        await _fetchPage();
      }
      _loadFavorites();
    } catch (e) {
      // ✅ If API fails, still try to load cache
      if (_allItems.isEmpty) {
        try {
          _loadCache();
        } catch (_) {
          _status = Error(e.toString());
          _errorMessage = e.toString();
        }
      }
      notifyListeners();
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await connectivity.checkConnectivity();
    _offlineMode = result == ConnectivityResult.none;
  }

  Future<void> _fetchPage() async {
    try {
      print('Fetching page $_currentPage, hasNext: $_hasNext, current items: ${_allItems.length}');
      final (newItems, hasNext) = await repo.getPage(_currentPage);
      print('Fetched ${newItems.length} new items, server hasNext: $hasNext');
      if (newItems.isEmpty && _allItems.isEmpty) {
        _status = const Empty();
      } else {
        _allItems.addAll(newItems);
        _hasNext = hasNext;
        _status = const Success();
        repo.writeCache(cacheBox, _allItems, _currentPage, _hasNext);
        print('Total items: ${_allItems.length}, updated hasNext: $_hasNext');
      }
    } on SocketException catch (e) {
      // ✅ Handle network failure gracefully
      print('SocketException: $e');
      _offlineMode = true;
      _loadCache();
    } catch (e) {
      print('Fetch error: $e');
      if (_allItems.isEmpty) {
        // Try cache if available
        try {
          _loadCache();
        } catch (_) {
          _status = Error(e.toString());
          _errorMessage = e.toString();
        }
      }
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _loadCache() {
    try {
      final cached = repo.readCache(cacheBox);
      if (cached != null && cached.items != null && cached.items is List<Character> && cached.items.isNotEmpty) {
        _allItems = List<Character>.from(cached.items);
        _currentPage = cached.page ?? 1;
        _hasNext = cached.hasNext ?? false;
        _status = const Success();
        print('Cache loaded: ${_allItems.length} items, hasNext: $_hasNext');
      } else {
        _status = const Empty();
        print('Cache empty or invalid');
      }
    } catch (e) {
      print('Cache error: $e');
      _status = Error(e.toString());
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext || _offlineMode || _status is! Success) {
      print('Load more skipped: loading=$_isLoadingMore, hasNext=$_hasNext, offline=$_offlineMode, status=$_status');
      return;
    }
    _isLoadingMore = true;
    notifyListeners();
    _currentPage++;
    await _fetchPage();
  }

  Future<void> refresh() async {
    await _checkConnectivity();
    if (_offlineMode) {
      _loadCache();
      return;
    }
    _allItems.clear();
    _currentPage = 1;
    _hasNext = true;
    _status = const Loading();
    notifyListeners();
    await _fetchPage();
  }

  Timer? _debounceTimer;

  void onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      _query = value.trim();
      _allItems.clear();
      _currentPage = 1;
      _hasNext = true;
      _status = const Loading();
      notifyListeners();
      if (_offlineMode) {
        _loadCache();
        _allItems = _allItems.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
        _status = _allItems.isEmpty ? const Empty() : const Success();
        notifyListeners();
      } else {
        await _fetchPage();
        _allItems = _allItems.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
        _status = _allItems.isEmpty ? const Empty() : const Success();
        notifyListeners();
      }
    });
  }

  void _loadFavorites() {
    _favorites = (favoritesBox.keys.cast<int>().toSet());
    notifyListeners();
  }

  void toggleFavorite(int id, bool isFavorite) {
    if (isFavorite) {
      favoritesBox.put(id, true);
      _favorites.add(id);
    } else {
      favoritesBox.delete(id);
      _favorites.remove(id);
    }
    notifyListeners();
  }

  List<Character> getFavorites() {
    return _allItems.where((c) => _favorites.contains(c.id)).toList();
  }

  bool get hasNext => _hasNext;
  bool get isLoadingMore => _isLoadingMore;
}
