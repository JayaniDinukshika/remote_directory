import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Add this import for CardSetSlideshowScreen dependencies

import ' features/directory/ presentation/card_set_slideshow_screen.dart';
import ' features/directory/ presentation/directory_screen.dart';
import 'core/theme_provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DirectoryScreen(isFavorites: false),
    DirectoryScreen(isFavorites: true), // Favorites tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isDesktop = constraints.maxWidth >= 1200;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Remote Directory'),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Toggle Theme',
                onPressed: () {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                },
              ),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.list), label: Text('All')),
                    NavigationRailDestination(icon: Icon(Icons.favorite), label: Text('Favorites')),
                  ],
                ),
              Expanded(
                child: Column(
                  children: [
                    const CardSetSlideshowScreen(), // Add the slideshow here
                    Expanded(child: _screens[_selectedIndex]), // Existing content
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.list), label: 'All'),
              NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
            ],
          ),
        );
      },
    );
  }
}