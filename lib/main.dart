import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import ' features/directory/ presentation/directory_screen.dart';
import ' features/directory/application/directory_provider.dart';

import 'core/theme_provider.dart';
import 'data/repository/character_repository.dart';
import 'data/remote/character_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final cacheBox = await Hive.openBox('cacheBox');
  runApp(MyApp(cacheBox: cacheBox));
}

class MyApp extends StatelessWidget {
  final Box cacheBox;
  const MyApp({super.key, required this.cacheBox});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DirectoryProvider(
            CharacterRepository(CharacterApi()),
            cacheBox,
          )..init(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Remote Directory',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            home: const DirectoryScreen(),
          );
        },
      ),
    );
  }
}
