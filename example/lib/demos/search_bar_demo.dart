import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class SearchBarDemoPage extends StatelessWidget {
  const SearchBarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          offset: 18,
          borderRadius: BorderRadius.circular(34),
          alignment: Alignment.bottomCenter,
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.interactive,
          duration: Duration(milliseconds: 360),
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 38,
                offset: Offset(0, 20),
              ),
            ],
          ),
          iconDecoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          iconWidth: 48,
          iconHeight: 48,
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 64, 28, 0),
              sliver: SliverToBoxAdapter(child: _PromptHeader()),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Icon(
                  Icons.explore_rounded,
                  size: 88,
                  color: Color(0x22000000),
                ),
              ),
            ),
          ],
        ),
        child: const _PromptDock(),
      ),
    );
  }
}

class _PromptHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(icon: Icons.menu_rounded),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            children: [
              _Segment(label: 'Ask', selected: true),
              _Segment(label: 'Imagine', selected: false),
            ],
          ),
        ),
        _RoundButton(icon: Icons.auto_awesome_rounded),
      ],
    );
  }
}

class _PromptDock extends StatelessWidget {
  const _PromptDock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask Anything',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.42),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const _CircleAction(icon: Icons.attach_file_rounded),
              const SizedBox(width: 10),
              const _PillAction(icon: Icons.lightbulb_outline, label: 'Expert'),
              const Spacer(),
              const _CircleAction(icon: Icons.mic_none_rounded),
              const SizedBox(width: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.graphic_eq_rounded),
                label: const Text('Speak'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, size: 30),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF6F6F3) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F4F2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon),
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
