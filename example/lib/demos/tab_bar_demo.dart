import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class TabBarDemoPage extends StatefulWidget {
  const TabBarDemoPage({super.key});

  @override
  State<TabBarDemoPage> createState() => _TabBarDemoPageState();
}

class _TabBarDemoPageState extends State<TabBarDemoPage> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(
          maxWidth: 400,
          offset: 32,
          borderRadius: BorderRadius.all(Radius.circular(32)),
          clip: Clip.none,
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
          duration: Duration(milliseconds: 460),
          extraBounce: 0.03,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
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
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            key: const Key('issues-content'),
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 58, 24, 128),
              children: const [
                _Header(),
                SizedBox(height: 26),
                _FilterRow(),
                SizedBox(height: 28),
                _SectionLabel(label: 'In Progress'),
                _IssueRow(
                  icon: Icons.signal_cellular_alt_rounded,
                  accent: Color(0xFFF0C93D),
                  text: 'HBT-1: Create habit creation flow',
                ),
                _IssueRow(
                  icon: Icons.priority_high_rounded,
                  accent: Color(0xFFFF8A5B),
                  text: 'HBT-4: Design daily habit list UI',
                ),
                SizedBox(height: 26),
                _SectionLabel(label: 'Todo'),
                _IssueRow(
                  icon: Icons.more_horiz_rounded,
                  accent: Color(0xFFBEBEBE),
                  text: 'HBT-2: Implement habit completion toast',
                ),
                _IssueRow(
                  icon: Icons.circle_outlined,
                  accent: Color(0xFFBEBEBE),
                  text: 'HBT-3: Refine weekly review screen',
                ),
              ],
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _DockButton(
                  icon: Icons.inbox_rounded,
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
              ),
              Expanded(
                child: _DockButton(
                  icon: Icons.center_focus_strong_rounded,
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
              ),
              Expanded(
                child: _DockButton(
                  icon: Icons.star_border_rounded,
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
              ),
              Expanded(
                child: _DockButton(
                  icon: Icons.keyboard_double_arrow_up_rounded,
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ),
              const SizedBox(width: 12),
              _SearchPuck(onTap: () => setState(() => _index = 4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Text(
            'My issues',
            style: TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              Icon(Icons.edit_square, size: 22),
              SizedBox(width: 18),
              Icon(Icons.more_horiz_rounded, size: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterPill(label: 'Assigned', selected: true),
          SizedBox(width: 12),
          _FilterPill(label: 'Created'),
          SizedBox(width: 12),
          _FilterPill(label: 'Subscribed'),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: selected ? Colors.black : Colors.black.withValues(alpha: 0.62),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.56),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.add_rounded, color: Colors.black.withValues(alpha: 0.56)),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({
    required this.icon,
    required this.accent,
    required this.text,
  });

  final IconData icon;
  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 23),
          const SizedBox(width: 10),
          Icon(Icons.circle_outlined, color: accent, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                height: 1.05,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F1EF) : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}

class _SearchPuck extends StatelessWidget {
  const _SearchPuck({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F8F6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.search_rounded, size: 26),
      ),
    );
  }
}
