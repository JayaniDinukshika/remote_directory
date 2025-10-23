import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/ models/character.dart';
import '../application/directory_provider.dart';
import 'character_detail_screen.dart';

class DirectoryScreen extends StatefulWidget {
  final bool enableRefreshIndicator;
  final bool isFavorites;

  const DirectoryScreen({
    super.key,
    required this.isFavorites,
    this.enableRefreshIndicator = true,
  });

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    // ❌ DO NOT call vm.init() here; it runs once from main() now.
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
      vm.loadMore();
    }
    _scrollPosition = _scrollController.position.pixels;
  }

  Future<void> _refresh(BuildContext context) async {
    final vm = Provider.of<DirectoryProvider>(context, listen: false);
    _scrollPosition = _scrollController.position.pixels;
    await vm.refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollPosition);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
                      'Offline — showing cached results',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    vm.onSearchChanged(value);
                    setState(() {}); // Refresh UI when typing
                  },
                  decoration: InputDecoration(
                    hintText: 'Search here...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        vm.onSearchChanged(''); // ✅ Clear search results
                        FocusScope.of(context).unfocus(); // Hide keyboard
                        setState(() {}); // Refresh UI to hide the icon
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.purple.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  cursorColor: Colors.purple,
                ),
              ),


            Expanded(
              child: RefreshIndicator(
                // ✅ use our method to restore scroll position
                onRefresh: () => _refresh(context),
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
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
            color: vm.favorites.contains(c.id) ? Colors.purple : Colors.grey,
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
        child: const Card(
          child: ListTile(
            leading: CircleAvatar(),
            title: SizedBox(width: double.infinity, height: 8),
            subtitle: SizedBox(width: double.infinity, height: 8),
          ),
        ),
      ),
    );
  }
}
