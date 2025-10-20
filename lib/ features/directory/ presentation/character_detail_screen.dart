import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/ models/character.dart';


class CharacterDetailScreen extends StatelessWidget {
  final Character character;
  const CharacterDetailScreen({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(character.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'img_${character.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: character.image,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(character.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(character.species)),
                const SizedBox(width: 8),
                Chip(
                  label: Text(character.status),
                  avatar: Icon(
                    character.status.toLowerCase() == 'alive' ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Extra',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${character.id}\n'
                  'Status: ${character.status}\n'
                  'Species: ${character.species}\n',
            ),
          ],
        ),
      ),
    );
  }
}
