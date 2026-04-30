// Greenfield: this page has no bottom bar yet. Add a hide-on-scroll floating
// bottom bar. The app uses Material 3.
import 'package:flutter/material.dart';

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 100,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text('Article ${i + 1}'),
            subtitle: const Text('A short summary of the article.'),
          ),
        ),
      ),
    );
  }
}
