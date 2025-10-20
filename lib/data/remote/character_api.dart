import 'package:dio/dio.dart';
import '../ models/character.dart';
import '../../core/api_endpoints.dart';


class PagedCharacters {
  final List<Character> results;
  final int page;
  final bool hasNext;

  PagedCharacters({required this.results, required this.page, required this.hasNext});
}

class CharacterApi {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 7),
      receiveTimeout: const Duration(seconds: 7),
    ),
  );

  Future<PagedCharacters> fetchPage({required int page}) async {
    final resp = await _dio.get(ApiEndpoints.characters, queryParameters: {'page': page});
    final data = resp.data as Map<String, dynamic>;
    final info = data['info'] as Map<String, dynamic>;
    final results = (data['results'] as List)
        .map((e) => Character.fromJson(e as Map<String, dynamic>))
        .toList();

    final next = info['next'] as String?;
    final hasNext = next != null && next.isNotEmpty;
    return PagedCharacters(results: results, page: page, hasNext: hasNext);
  }
}
