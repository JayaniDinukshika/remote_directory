import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../directory/application/directory_provider.dart';
import '../../../core/theme_provider.dart';
import 'character_detail_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final p = _scrollController.position;
      if (p.pixels >= p.maxScrollExtent - 300) {
        context.read<DirectoryProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DirectoryProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Directory'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            tooltip: themeProvider.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (vm.offlineMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.amber.withOpacity(0.2),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 18),
                  SizedBox(width: 8),
                  Text('Offline - showing cached results'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              onChanged: vm.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name/species/status',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              child: _buildBody(vm),
            ),
          ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: vm.status == LoadStatus.loading,
        child: FloatingActionButton.small(
          onPressed: () {},
          tooltip: 'Loading',
          child: const CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildBody(DirectoryProvider vm) {
    if (vm.status == LoadStatus.loading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.status == LoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vm.errorMessage ?? 'Something went wrong'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: vm.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (vm.items.isEmpty) {
      return const Center(child: Text('No items'));
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (_, i) {
        final c = vm.items[i];
        return ListTile(
          leading: Hero(
            tag: 'img_${c.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: c.image,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (_, __, ___) =>
                const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          title:
          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${c.species} • ${c.status}',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 250),
              pageBuilder: (_, __, ___) =>
                  CharacterDetailScreen(character: c),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemCount: vm.items.length,
    );
  }
}
