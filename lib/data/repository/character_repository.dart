import 'package:hive_flutter/hive_flutter.dart';

import '../ models/character.dart';
import '../remote/character_api.dart';

class CharacterRepository {
  final CharacterApi api;
  CharacterRepository(this.api);

  // ✅ Correct record return type
  Future<(List<Character>, bool)> getPage(int page) async {
    final paged = await api.fetchPage(page: page);
    return (paged.results, paged.hasNext);
  }

  // Cache helpers (store as plain Maps to avoid adapters)
  static const _cacheKey = 'lastCharacters';
  static const _pageKey = 'lastPage';
  static const _hasNextKey = 'lastHasNext';
  static const _tsKey = 'lastTs';

  void writeCache(Box cache, List<Character> items, int page, bool hasNext) {
    cache.put(_cacheKey, items.map((e) => e.toJson()).toList());
    cache.put(_pageKey, page);
    cache.put(_hasNextKey, hasNext);
    cache.put(_tsKey, DateTime.now().toIso8601String());
  }

  ({List<Character> items, int page, bool hasNext, DateTime? ts})
  readCache(Box cache) {
    final raw = (cache.get(_cacheKey) as List?)?.cast<Map>() ?? <Map>[];
    final items = raw
        .map((e) => Character.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final page = (cache.get(_pageKey) as int?) ?? 1;
    final hasNext = (cache.get(_hasNextKey) as bool?) ?? false;
    final tsStr = cache.get(_tsKey) as String?;
    return (
    items: items,
    page: page,
    hasNext: hasNext,
    ts: tsStr == null ? null : DateTime.tryParse(tsStr),
    );
  }
}
