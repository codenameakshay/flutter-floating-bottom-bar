import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class ReaderControlsRecipe extends StatefulWidget {
  const ReaderControlsRecipe({super.key});

  @override
  State<ReaderControlsRecipe> createState() => _ReaderControlsRecipeState();
}

class _ReaderControlsRecipeState extends State<ReaderControlsRecipe> {
  final _bar = BottomBarController();
  bool _bookmarked = false;
  double _fontSize = 17;

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reader')),
      body: BottomBar(
        controller: _bar,
        showIcon: false,
        body: Semantics(
          container: true,
          label: 'Article. Tap to show reading controls',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _bar.show,
            child: BottomBarBodyPadding(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  for (var i = 1; i <= 12; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Paragraph $i. $_lorem',
                        style: TextStyle(fontSize: _fontSize, height: 1.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Smaller text',
              onPressed: _fontSize > 13
                  ? () => setState(() => _fontSize -= 2)
                  : null,
              icon: const Icon(Icons.text_decrease),
            ),
            IconButton(
              tooltip: 'Larger text',
              onPressed: _fontSize < 27
                  ? () => setState(() => _fontSize += 2)
                  : null,
              icon: const Icon(Icons.text_increase),
            ),
            IconButton(
              tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark',
              onPressed: () => setState(() => _bookmarked = !_bookmarked),
              icon: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_border),
            ),
          ],
        ),
      ),
    );
  }
}

const _lorem =
    'Good reading starts before the first sentence. Put the phone aside and '
    'let the page become the only place you need to be for a while. Scroll '
    'down and the controls step out of the way. Tap the page to bring them '
    'back without losing your place.';
