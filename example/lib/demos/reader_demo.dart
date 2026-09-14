import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class ReaderDemoPage extends StatefulWidget {
  const ReaderDemoPage({super.key, this.controller});

  final BottomBarController? controller;

  @override
  State<ReaderDemoPage> createState() => _ReaderDemoPageState();
}

class _ReaderDemoPageState extends State<ReaderDemoPage> {
  late final BottomBarController _controller =
      widget.controller ?? BottomBarController();
  var _largeText = false;
  var _bookmarked = false;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScale = _largeText ? 1.14 : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      appBar: AppBar(
        title: const Text('Reader'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: BottomBar(
        controller: _controller,
        showIcon: false,
        layout: const BottomBarLayout.adaptive(
          maxWidth: 380,
          offset: 20,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
          duration: Duration(milliseconds: 360),
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x12000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
        ),
        body: Stack(
          key: const Key('reader-body'),
          fit: StackFit.expand,
          children: [
            BottomBarBodyPadding(
              child: ListView(
                key: const Key('reader-list'),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                children: [
                  const _ReaderHeader(),
                  const SizedBox(height: 28),
                  for (final section in _articleSections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: _ArticleSection(
                        section: section,
                        textScale: textScale,
                      ),
                    ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                if (_controller.isVisible) return const SizedBox.shrink();
                return Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: FilledButton.icon(
                        key: const Key('reader-reveal'),
                        onPressed: _controller.show,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Show reading controls'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 52),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        child: Padding(
          key: const Key('reader-controls'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Reading controls',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                key: const Key('reader-text-size'),
                tooltip: _largeText ? 'Use regular text' : 'Use large text',
                onPressed: () => setState(() => _largeText = !_largeText),
                icon: const Icon(Icons.format_size_rounded),
              ),
              IconButton(
                key: const Key('reader-bookmark'),
                tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark article',
                onPressed: () => setState(() => _bookmarked = !_bookmarked),
                icon: Icon(
                  _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A quiet guide to reading well',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 12),
        Text(
          'Take your time. The controls follow you until you need a little more room to read.',
          style: TextStyle(
            color: Color(0x99000000),
            fontSize: 17,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ArticleSection extends StatelessWidget {
  const _ArticleSection({required this.section, required this.textScale});

  final _ArticleSectionData section;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final paragraph in section.paragraphs) ...[
          Text(
            paragraph,
            style: TextStyle(
              color: Color(0xDD000000),
              fontSize: 17 * textScale,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ArticleSectionData {
  const _ArticleSectionData(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

const _articleSections = <_ArticleSectionData>[
  _ArticleSectionData('Begin with attention', [
    'Good reading starts before the first sentence. Put the phone aside, notice the pace of your breathing, and let the page become the only place you need to be for a while.',
    'Attention is not a switch that stays on forever. It is a small decision you can make again each time your mind wanders. That return is part of reading, too.',
  ]),
  _ArticleSectionData('Let the shape of an idea appear', [
    'A useful paragraph often needs a moment before it becomes clear. Follow its examples, hold its questions, and resist the urge to turn every line into a conclusion immediately.',
    'When an argument feels difficult, try asking what problem it is trying to solve. The answer gives each detail a place, and the page becomes easier to carry in your head.',
  ]),
  _ArticleSectionData('Make room for memory', [
    'The best notes are small enough to invite a return. A sentence in the margin, a question at the end of a chapter, or one phrase copied into a notebook can keep the conversation open.',
    'Remembering is helped by distance. Close the book, describe what changed in your thinking, and come back later with enough space to notice what stayed.',
  ]),
  _ArticleSectionData('Read with other people', [
    'A book becomes larger when its ideas meet another person. Share the passage that stayed with you, listen for a different emphasis, and let disagreement make the edges of an idea visible.',
    'Conversation also makes room for delight. A story can be useful because it gives us a new fact, and it can be useful because it gives us a new way to see a familiar morning.',
  ]),
  _ArticleSectionData('Return tomorrow', [
    'A reading practice does not need to be dramatic. Ten quiet pages, repeated often, can change the texture of a week. The goal is to build a place you can reliably visit.',
    'Leave a little unfinished. The next page is an invitation, and the easiest way to keep reading is to stop while there is still something you want to understand.',
  ]),
];
