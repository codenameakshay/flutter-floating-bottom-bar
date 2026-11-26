import 'package:material_ui/material_ui.dart';

import 'composer.dart';
import 'long_labels.dart';
import 'mini_player.dart';
import 'reader_controls.dart';
import 'scroll_under.dart';
import 'selection_dock.dart';
import 'split_bar.dart';

/// Every recipe, keyed by its playground slug (`/#/recipe-<name>` on web).
final recipes =
    <({String slug, String title, String useWhen, WidgetBuilder builder})>[
      (
        slug: 'recipe-composer',
        title: 'Composer',
        useWhen: 'A chat or prompt input that sits above the keyboard.',
        builder: (_) => const ComposerRecipe(),
      ),
      (
        slug: 'recipe-selection-dock',
        title: 'Selection dock',
        useWhen: 'Long-press selects rows and the nav turns into actions.',
        builder: (_) => const SelectionDockRecipe(),
      ),
      (
        slug: 'recipe-reader-controls',
        title: 'Reader controls',
        useWhen: 'Tapping the page brings the controls back in place.',
        builder: (_) => const ReaderControlsRecipe(),
      ),
      (
        slug: 'recipe-scroll-under',
        title: 'Scroll under',
        useWhen:
            'Slivers scroll under the bar and the last row still clears it.',
        builder: (_) => const ScrollUnderRecipe(),
      ),
      (
        slug: 'recipe-long-labels',
        title: 'Long labels',
        useWhen: 'Five long tab labels at narrow widths, large text and RTL.',
        builder: (_) => const LongLabelsRecipe(),
      ),
      (
        slug: 'recipe-mini-player',
        title: 'Mini player',
        useWhen: 'A now-playing row above the tabs that shrinks with the bar.',
        builder: (_) => const MiniPlayerRecipe(),
      ),
      (
        slug: 'recipe-split-bar',
        title: 'Split bar',
        useWhen: 'An iOS 26 style pill with a profile and a search circle.',
        builder: (_) => const SplitBarRecipe(),
      ),
    ];

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: ListView(
        children: [
          for (final recipe in recipes)
            ListTile(
              title: Text(recipe.title),
              subtitle: Text(recipe.useWhen),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed('/${recipe.slug}'),
            ),
        ],
      ),
    );
  }
}
