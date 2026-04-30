import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class BasicDemoPage extends StatelessWidget {
  const BasicDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: BottomBar(
        layout: BottomBarLayout(
          width: 312,
          offset: 24,
          borderRadius: BorderRadius.circular(32),
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 32,
                offset: Offset(0, 18),
              ),
            ],
          ),
          iconDecoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          iconWidth: 44,
          iconHeight: 44,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 140),
          itemCount: 24,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (_, i) => _NoteTile(index: i),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.inbox_rounded),
              Text(
                'Floating widget',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Icon(Icons.arrow_upward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFF4D35E),
      const Color(0xFF8FD7C7),
      const Color(0xFFFFA37A),
      const Color(0xFFC9C6FF),
    ];
    return Row(
      children: [
        Container(
          width: 12,
          height: 48,
          decoration: BoxDecoration(
            color: colors[index % colors.length],
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scroll item ${index + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cupertino motion keeps direction changes fluid.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.48)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
