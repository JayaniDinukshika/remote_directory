// import 'package:dio/dio.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// import 'package:hive_flutter/hive_flutter.dart';
//
// import 'package:remote_directory/data/repository/character_repository.dart';
// import 'package:remote_directory/data/remote/character_api.dart';
//
// @GenerateMocks([CharacterApi])
// void main() {
//   late MockCharacterApi mockApi;
//   late CharacterRepository repo;
//
//   setUp(() {
//     mockApi = MockCharacterApi();
//     repo = CharacterRepository(mockApi);
//   });
//
//   test('fetches page successfully', async () {
//   final mockResponse = PagedCharacters(
//   results: [Character(id: 1, name: 'Rick', status: 'Alive', species: 'Human', image: '')],
//   page: 1,
//   hasNext: true,
//   );
//   when(mockApi.fetchPage(page: 1)).thenAnswer((_) async => mockResponse);
//
//   final (items, hasNext) = await repo.getPage(1, '');
//
//   expect(items.length, 1);
//   expect(hasNext, true);
//   verify(mockApi.fetchPage(page: 1)).called(1);
//   });
//
//   test('handles error', async () {
//   when(mockApi.fetchPage(page: 1)).thenThrow(DioException(requestOptions: RequestOptions()));
//
//   expect(() async => await repo.getPage(1, ''), throwsException);
//   });
// }