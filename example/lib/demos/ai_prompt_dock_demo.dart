import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class AiPromptDockDemoPage extends StatefulWidget {
  const AiPromptDockDemoPage({super.key});

  @override
  State<AiPromptDockDemoPage> createState() => _AiPromptDockDemoPageState();
}

class _AiPromptDockDemoPageState extends State<AiPromptDockDemoPage> {
  final _draftController = TextEditingController();
  final _focusNode = FocusNode();
  final _barController = BottomBarController();
  final _messages = <String>[];
  bool _isImagineMode = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _draftController.dispose();
    _barController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _barController.show();
    }
    setState(() {});
  }

  void _submit() {
    final text = _draftController.text.trim();
    if (text.isEmpty) {
      _focusNode.requestFocus();
      return;
    }

    setState(() {
      _messages.add(text);
      _draftController.clear();
    });
    _focusNode.requestFocus();
    _barController.show();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: BottomBar(
          controller: _barController,
          layout: const BottomBarLayout.adaptive(
            maxWidth: 440,
            offset: 24,
            borderRadius: BorderRadius.all(Radius.circular(28)),
            alignment: Alignment.bottomCenter,
          ),
          motion: const BottomBarMotion.cupertino(
            preset: BottomBarCupertinoMotion.interactive,
            duration: Duration(milliseconds: 360),
          ),
          scrollBehavior: BottomBarScrollBehavior(
            hideOnScroll: !_focusNode.hasFocus,
            showOnScrollEnd: !_focusNode.hasFocus,
          ),
          theme: BottomBarThemeData(
            barDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x10000000)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 30,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            iconDecoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            iconWidth: 40,
            iconHeight: 40,
          ),
          body: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
                sliver: SliverToBoxAdapter(
                  child: _PromptHeader(
                    isImagineMode: _isImagineMode,
                    onModeChanged: (value) =>
                        setState(() => _isImagineMode = value),
                  ),
                ),
              ),
              if (_messages.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.explore_rounded,
                          size: 64,
                          color: Color(0x55000000),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Start with a prompt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ask a question or imagine something new.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0x99000000),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverList.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TranscriptBubble(message: _messages[index]),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: BottomBarBodyPadding(child: SizedBox(height: 1)),
              ),
            ],
          ),
          child: _PromptComposer(
            controller: _draftController,
            focusNode: _focusNode,
            isImagineMode: _isImagineMode,
            onSubmit: _submit,
            onDismissKeyboard: () => _focusNode.unfocus(),
          ),
        ),
      ),
    );
  }
}

class _PromptHeader extends StatelessWidget {
  const _PromptHeader({
    required this.isImagineMode,
    required this.onModeChanged,
  });

  final bool isImagineMode;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        IconButton(
          tooltip: 'Back to demos',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Ask')),
            ButtonSegment(value: true, label: Text('Imagine')),
          ],
          selected: {isImagineMode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

class _PromptComposer extends StatelessWidget {
  const _PromptComposer({
    required this.controller,
    required this.focusNode,
    required this.isImagineMode,
    required this.onSubmit,
    required this.onDismissKeyboard,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isImagineMode;
  final VoidCallback onSubmit;
  final VoidCallback onDismissKeyboard;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.viewInsetsOf(context).bottom > 0 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 14, 12, compact ? 6 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isImagineMode ? 'Imagine something' : 'Ask anything',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.58),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: compact ? 2 : 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: isImagineMode
                  ? 'Describe an idea...'
                  : 'What would you like to explore?',
              filled: true,
              fillColor: const Color(0xFFF4F4F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: focusNode.hasFocus
                  ? IconButton(
                      tooltip: 'Dismiss keyboard',
                      onPressed: onDismissKeyboard,
                      icon: const Icon(Icons.keyboard_hide_rounded),
                    )
                  : null,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) => SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: value.text.trim().isNotEmpty ? onSubmit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E5E1),
                  disabledForegroundColor: const Color(0x88000000),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                label: const Text(
                  'Send',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptBubble extends StatelessWidget {
  const _TranscriptBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
