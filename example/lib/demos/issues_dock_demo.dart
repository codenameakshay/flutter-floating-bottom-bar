import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class IssuesDockDemoPage extends StatefulWidget {
  const IssuesDockDemoPage({super.key});

  @override
  State<IssuesDockDemoPage> createState() => _IssuesDockDemoPageState();
}

class _IssuesDockDemoPageState extends State<IssuesDockDemoPage> {
  final _barController = BottomBarController();
  final _selectedIssueIds = <String>{};
  final _issues = <_Issue>[
    const _Issue(
      id: 'HBT-1',
      title: 'Create habit creation flow',
      status: _IssueStatus.open,
      icon: Icons.signal_cellular_alt_rounded,
      accent: Color(0xFFF0C93D),
    ),
    const _Issue(
      id: 'HBT-4',
      title: 'Design daily habit list UI',
      status: _IssueStatus.open,
      icon: Icons.priority_high_rounded,
      accent: Color(0xFFFF8A5B),
    ),
    const _Issue(
      id: 'HBT-2',
      title: 'Implement habit completion toast',
      status: _IssueStatus.todo,
      icon: Icons.more_horiz_rounded,
      accent: Color(0xFFBEBEBE),
    ),
    const _Issue(
      id: 'HBT-3',
      title: 'Refine weekly review screen',
      status: _IssueStatus.todo,
      icon: Icons.circle_outlined,
      accent: Color(0xFFBEBEBE),
    ),
  ];

  _IssueFilter _filter = _IssueFilter.all;

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  List<_Issue> get _visibleIssues => _issues.where((issue) {
    return _filter == _IssueFilter.all ||
        (_filter == _IssueFilter.open && issue.status == _IssueStatus.open) ||
        (_filter == _IssueFilter.todo && issue.status == _IssueStatus.todo);
  }).toList();

  void _setFilter(_IssueFilter filter) {
    setState(() => _filter = filter);
    _barController.show();
  }

  void _toggleIssue(String id) {
    setState(() {
      if (!_selectedIssueIds.add(id)) _selectedIssueIds.remove(id);
    });
    _barController.show();
  }

  void _clearSelection() {
    setState(_selectedIssueIds.clear);
    _barController.show();
  }

  void _archiveSelected() {
    final count = _selectedIssueIds.length;
    if (count == 0) return;

    setState(() {
      _issues.removeWhere((issue) => _selectedIssueIds.contains(issue.id));
      _selectedIssueIds.clear();
    });
    _barController.show();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Archived $count issue${count == 1 ? '' : 's'}')),
    );
  }

  List<Widget> _buildIssueContent() {
    final visible = _visibleIssues;
    final open = visible.where((issue) => issue.status == _IssueStatus.open);
    final todo = visible.where((issue) => issue.status == _IssueStatus.todo);

    return [
      const _Header(),
      const SizedBox(height: 28),
      if (open.isNotEmpty) ...[
        const _SectionLabel(label: 'Open'),
        ...open.map(_buildIssueRow),
      ],
      if (todo.isNotEmpty) ...[
        if (open.isNotEmpty) const SizedBox(height: 4),
        const _SectionLabel(label: 'Todo'),
        ...todo.map(_buildIssueRow),
      ],
      if (visible.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 18),
          child: Text(
            'No issues in this view',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
    ];
  }

  Widget _buildIssueRow(_Issue issue) {
    return _IssueRow(
      key: Key('issue-row-${issue.id}'),
      issue: issue,
      selected: _selectedIssueIds.contains(issue.id),
      onToggle: () => _toggleIssue(issue.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIssueIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: SizedBox.expand(
        child: BottomBar(
          controller: _barController,
          scrollBehavior: BottomBarScrollBehavior(
            hideOnScroll: selectedCount == 0,
            showOnScrollEnd: selectedCount == 0,
          ),
          layout: const BottomBarLayout.adaptive(
            maxWidth: 400,
            offset: 32,
            borderRadius: BorderRadius.all(Radius.circular(32)),
            clip: Clip.none,
            fit: StackFit.expand,
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
                key: const Key('issues-scroll'),
                padding: const EdgeInsets.fromLTRB(24, 58, 24, 24),
                children: [
                  ..._buildIssueContent(),
                  const BottomBarBodyPadding(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: selectedCount == 0
                ? SizedBox(
                    key: const Key('normal-dock'),
                    height: 68,
                    child: _NormalDock(
                      filter: _filter,
                      onFilterSelected: _setFilter,
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 68),
                    child: _SelectionDock(
                      selectedCount: selectedCount,
                      onArchive: _archiveSelected,
                      onClear: _clearSelection,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

enum _IssueStatus { open, todo }

enum _IssueFilter { all, open, todo }

class _Issue {
  const _Issue({
    required this.id,
    required this.title,
    required this.status,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String title;
  final _IssueStatus status;
  final IconData icon;
  final Color accent;
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackButton(onPressed: () => Navigator.maybePop(context)),
        const Expanded(
          child: Text(
            'My issues',
            style: TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({
    super.key,
    required this.issue,
    required this.selected,
    required this.onToggle,
  });

  final _Issue issue;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: selected,
      label: '${issue.id}: ${issue.title}',
      onTap: onToggle,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Checkbox(
                    key: Key('issue-checkbox-${issue.id}'),
                    value: selected,
                    onChanged: (_) => onToggle(),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                    activeColor: Colors.black,
                  ),
                  Icon(issue.icon, color: issue.accent, size: 23),
                  const SizedBox(width: 10),
                  Icon(Icons.circle_outlined, color: issue.accent, size: 23),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${issue.id}: ${issue.title}',
                      maxLines: 2,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _NormalDock extends StatelessWidget {
  const _NormalDock({required this.filter, required this.onFilterSelected});

  final _IssueFilter filter;
  final ValueChanged<_IssueFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return BottomBarItems(
      spacing: MainAxisAlignment.spaceAround,
      children: [
        BottomBarItem(
          key: const Key('dock-filter-all'),
          icon: const Icon(Icons.inbox_rounded),
          semanticLabel: 'All issues',
          selected: filter == _IssueFilter.all,
          onTap: () => onFilterSelected(_IssueFilter.all),
        ),
        BottomBarItem(
          key: const Key('dock-filter-open'),
          icon: const Icon(Icons.center_focus_strong_rounded),
          semanticLabel: 'Open',
          selected: filter == _IssueFilter.open,
          onTap: () => onFilterSelected(_IssueFilter.open),
        ),
        BottomBarItem(
          key: const Key('dock-filter-todo'),
          icon: const Icon(Icons.more_horiz_rounded),
          semanticLabel: 'Todo',
          selected: filter == _IssueFilter.todo,
          onTap: () => onFilterSelected(_IssueFilter.todo),
        ),
      ],
    );
  }
}

class _SelectionDock extends StatelessWidget {
  const _SelectionDock({
    required this.selectedCount,
    required this.onArchive,
    required this.onClear,
  });

  final int selectedCount;
  final VoidCallback onArchive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$selectedCount selected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          key: const Key('archive-selected'),
          tooltip: 'Archive',
          onPressed: onArchive,
          icon: const Icon(Icons.archive_outlined),
        ),
        IconButton(
          key: const Key('clear-selection'),
          tooltip: 'Clear selection',
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
