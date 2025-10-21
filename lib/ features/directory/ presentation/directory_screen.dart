import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remote_directory/%20features/directory/application/directory_provider.dart';
import 'package:remote_directory/data/%20models/character.dart';
import 'package:shimmer/shimmer.dart';

import 'character_detail_screen.dart';

class DirectoryScreen extends StatefulWidget {
  final bool isFavorites;
  const DirectoryScreen({super.key, required this.isFavorites});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _scrollController = ScrollController();
  final _globalKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        context.read<DirectoryProvider>().loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DirectoryProvider>();
    final items = widget.isFavorites ? vm.getFavorites() : vm.items;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final int columns = isMobile ? 1 : isTablet ? 2 : 3;

        return Column(
          children: [
            if (vm.offlineMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 18, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Offline - showing cached results', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            if (!widget.isFavorites)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: vm.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.refresh,
                child: vm.status is Loading && items.isEmpty
                    ? _buildShimmerGrid(columns)
                    : vm.status is Error
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vm.errorMessage ?? 'Error', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: vm.refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                    : items.isEmpty
                    ? const Center(child: Text('No items found'))
                    : AnimatedList(
                  key: _globalKey,
                  controller: _scrollController,
                  initialItemCount: items.length,
                  itemBuilder: (context, index, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: _buildItem(items[index], columns),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(Character c, int columns) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Hero(
          tag: 'img_${c.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: c.image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(c.name, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text('${c.species} • ${c.status}', style: Theme.of(context).textTheme.bodyMedium),
        trailing: IconButton(
          icon: Icon(
            Provider.of<DirectoryProvider>(context).favorites.contains(c.id) ? Icons.favorite : Icons.favorite_border,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            final vm = Provider.of<DirectoryProvider>(context, listen: false);
            vm.toggleFavorite(c.id, !vm.favorites.contains(c.id));
          },
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CharacterDetailScreen(character: c)),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid(int columns) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 3,
      ),
      itemCount: 10,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          child: ListTile(
            leading: const CircleAvatar(),
            title: Container(width: double.infinity, height: 8, color: Colors.white),
            subtitle: Container(width: double.infinity, height: 8, color: Colors.white),
          ),
        ),
      ),
    );
  }
}