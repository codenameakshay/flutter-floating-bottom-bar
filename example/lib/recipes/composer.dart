import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class ComposerRecipe extends StatefulWidget {
  const ComposerRecipe({super.key});

  @override
  State<ComposerRecipe> createState() => _ComposerRecipeState();
}

class _ComposerRecipeState extends State<ComposerRecipe> {
  final _text = TextEditingController();
  final _messages = <String>[];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final message = _text.text.trim();
    if (message.isEmpty) return;
    setState(() => _messages.insert(0, message));
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Composer')),
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(
          maxWidth: 560,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false),
        body: BottomBarBodyPadding(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) => _Bubble(_messages[i]),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 4, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Ask anything',
                    ),
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Send',
                onPressed: _send,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text),
      ),
    );
  }
}
