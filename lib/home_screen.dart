import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import ' features/directory/ presentation/card_set_slideshow_screen.dart';
import ' features/directory/ presentation/directory_screen.dart';
import ' features/directory/application/directory_provider.dart';
import 'core/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DirectoryScreen(isFavorites: false, enableRefreshIndicator: false),
    DirectoryScreen(isFavorites: true,enableRefreshIndicator: false), // Favorites tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future<void> _onRefresh(BuildContext context) async {
    final vm = Provider.of<DirectoryProvider>(context, listen: false);
    await vm.refresh();
    // TODO: Add refresh logic for CardSetSlideshowScreen if needed
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
            backgroundColor: isDark ? Colors.grey[900] : Colors.white, // Background color for the navigation bar
            indicatorColor: isDark ? Colors.purpleAccent : Colors.purple[100], // Color for the selected item's indicator
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.list),
                selectedIcon: Icon(Icons.list, color: Colors.purple), // Color for selected icon
                label: 'All',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite),
                selectedIcon: Icon(Icons.favorite, color: Colors.purple), // Color for selected icon
                label: 'Favorites',
              ),
            ],
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        );
      },
    );
  }
}