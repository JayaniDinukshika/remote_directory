import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/ models/character.dart';
import '../application/directory_provider.dart';
import 'character_detail_screen.dart';

class DirectoryScreen extends StatefulWidget {
  final bool isFavorites;
  const DirectoryScreen({super.key, required this.isFavorites});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final vm = context.read<DirectoryProvider>();
    // Initialize data (handles offline/online modes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.init();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final vm = context.read<DirectoryProvider>();
    if (widget.isFavorites) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300 &&
        !vm.isLoadingMore &&
        vm.hasNext &&
        !vm.offlineMode) {
      // Only load more if online
      vm.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DirectoryProvider>();
    final items = widget.isFavorites ? vm.getFavorites() : vm.items;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final int columns = isMobile ? 1 : isTablet ? 2 : 3;

        return Column(
          children: [
            // ✅ Offline banner
            if (vm.offlineMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.orange.withOpacity(0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Offline - showing cached results',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.orange),
                    ),
                  ],
                ),
              ),

            if (!widget.isFavorites)
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: vm.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.refresh,
                child: Builder(
                  builder: (context) {
                    if (vm.status is Loading && items.isEmpty) {
                      return _buildShimmerGrid(columns);
                    } else if (vm.status is Error) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vm.errorMessage ?? 'Error',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: vm.refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (items.isEmpty) {
                      return const Center(child: Text('No items found'));
                    } else {
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: items.length + (vm.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return _buildItem(items[index]);
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(Character c) {
    final vm = Provider.of<DirectoryProvider>(context, listen: false);

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
              placeholder: (context, url) =>
              const CircularProgressIndicator(strokeWidth: 2),
              errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image),
            ),
          ),
        ),
        title: Text(c.name, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text('${c.species} • ${c.status}',
            style: Theme.of(context).textTheme.bodyMedium),
        trailing: IconButton(
          icon: Icon(
            vm.favorites.contains(c.id)
                ? Icons.favorite
                : Icons.favorite_border,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            vm.toggleFavorite(c.id, !vm.favorites.contains(c.id));
          },
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CharacterDetailScreen(character: c),
          ),
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
            title: Container(
                width: double.infinity, height: 8, color: Colors.white),
            subtitle: Container(
                width: double.infinity, height: 8, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
