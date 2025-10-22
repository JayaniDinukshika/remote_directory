import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import ' features/directory/application/directory_provider.dart';

import 'core/theme_provider.dart';
import 'data/repository/character_repository.dart';
import 'data/remote/character_api.dart';
import 'splash_screen.dart';
import 'landing_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final cacheBox = await Hive.openBox('cacheBox');
  final favoritesBox = await Hive.openBox('favoritesBox');
  runApp(MyApp(cacheBox: cacheBox, favoritesBox: favoritesBox));
}

class MyApp extends StatelessWidget {
  final Box cacheBox;
  final Box favoritesBox;
  const MyApp({super.key, required this.cacheBox, required this.favoritesBox});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DirectoryProvider(
            repo: CharacterRepository(CharacterApi()),
            cacheBox: cacheBox,
            favoritesBox: favoritesBox,
            connectivity: Connectivity(),
          )..init(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Remote Directory',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
                surface: Colors.grey[50],
              ),
              scaffoldBackgroundColor: Colors.grey[50],
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: true,
                scrolledUnderElevation: 0,
              ),
              cardTheme:  CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              textTheme: const TextTheme(
                headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                bodyLarge: TextStyle(fontSize: 16),
                bodyMedium: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
                surface: Colors.grey[900],
              ),
              scaffoldBackgroundColor: Colors.grey[900],
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: true,
                scrolledUnderElevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              textTheme: const TextTheme(
                headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                bodyLarge: TextStyle(fontSize: 16),
                bodyMedium: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
