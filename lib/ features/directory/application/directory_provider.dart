import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/ models/character.dart';
import '../../../data/repository/character_repository.dart';

sealed class LoadStatus {
  const LoadStatus();
}
class Loading extends LoadStatus { const Loading(); }
class Success extends LoadStatus { const Success(); }
class Empty extends LoadStatus { const Empty(); }
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
  bool get isLoadingMore => _isLoadingMore;

  bool get hasNext => _hasNext;

  Timer? _debounceTimer;

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
    try {
      final result = await connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        _offlineMode = true;
      } else {
        try {
          final lookup = await InternetAddress.lookup('example.com')
              .timeout(const Duration(seconds: 3));
          _offlineMode = lookup.isEmpty || lookup[0].rawAddress.isEmpty;
        } on SocketException {
          _offlineMode = true;
        } on TimeoutException {
          _offlineMode = true;
        }
      }
    } catch (_) {
      _offlineMode = true;
    }
    notifyListeners(); // update offline banner
  }

  Future<void> _fetchPage() async {
    try {
      final (newItems, hasNext) = await repo.getPage(_currentPage);

      if (newItems.isEmpty && _allItems.isEmpty) {
        _status = const Empty();
      } else {
        final ids = _allItems.map((e) => e.id).toSet();
        _allItems.addAll(newItems.where((it) => !ids.contains(it.id)));

        _hasNext = hasNext;
        _status = const Success();

        repo.writeCache(cacheBox, _allItems, _currentPage, _hasNext);
      }
    } on SocketException catch (e) {
      _offlineMode = true;
      _errorMessage = e.toString();
      _loadCache(); // fallback
    } catch (e) {
      _errorMessage = e.toString();
      if (_allItems.isEmpty) {
        try {
          _loadCache();
        } catch (_) {
          _status = Error(e.toString());
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
      _allItems = List<Character>.from(cached.items);
      _currentPage = cached.page;
      _hasNext = cached.hasNext;
      _status = _allItems.isEmpty ? const Empty() : const Success();
    } catch (e) {
      _status = Error(e.toString());
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext || _offlineMode || _status is! Success) {
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

  void onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      _query = value.trim().toLowerCase();

      if (_offlineMode) {
        // Filter cached results
        _status = const Loading();
        notifyListeners();
        _loadCache();
        _allItems = _allItems
            .where((c) => c.name.toLowerCase().contains(_query))
            .toList();
        _status = _allItems.isEmpty ? const Empty() : const Success();
        notifyListeners();
      } else {
        _allItems.clear();
        _currentPage = 1;
        _hasNext = true;
        _status = const Loading();
        notifyListeners();

        await _fetchPage();

        _allItems = _allItems
            .where((c) => c.name.toLowerCase().contains(_query))
            .toList();
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
    if (isFavorite && !_favorites.contains(id)) {
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
