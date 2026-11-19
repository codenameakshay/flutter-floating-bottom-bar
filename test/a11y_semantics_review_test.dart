import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/semantics.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

class _StatefulTab extends StatefulWidget {
  const _StatefulTab({super.key, required this.name});

  final String name;

  @override
  State<_StatefulTab> createState() => _StatefulTabState();
}

class _StatefulTabState extends State<_StatefulTab> {
  @override
  Widget build(BuildContext context) =>
      BottomBarItem(icon: const Icon(Icons.home), label: Text(widget.name));
}

void main() {
  testWidgets('keyed independent tabs keep state when reordered', (
    tester,
  ) async {
    Widget row(List<String> names) => _app(
      BottomBarItems(
        children: [
          for (final name in names)
            _StatefulTab(key: ValueKey(name), name: name),
        ],
      ),
    );
    await tester.pumpWidget(row(['Home', 'Inbox']));
    final home = tester.state(find.byKey(const ValueKey('Home')));
    final inbox = tester.state(find.byKey(const ValueKey('Inbox')));
    await tester.pumpWidget(row(['Inbox', 'Home']));
    expect(tester.state(find.byKey(const ValueKey('Home'))), same(home));
    expect(tester.state(find.byKey(const ValueKey('Inbox'))), same(inbox));
  });

  for (final behavior in BottomBarLabelBehavior.values) {
    testWidgets('rich labels remain named with $behavior', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            indicator: const BottomBarIndicator.pill(),
            labelBehavior: behavior,
            children: [
              BottomBarItem(
                icon: Icon(Icons.home),
                label: Text.rich(TextSpan(text: 'Home')),
              ),
              BottomBarItem(
                icon: Icon(Icons.inbox),
                label: Text.rich(TextSpan(text: 'Inbox')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(semanticsLabels(tester), [
        'Home, Tab 1 of 2',
        'Inbox, Tab 2 of 2',
      ]);
      semantics.dispose();
    });
  }
  testWidgets('icon semantics do not repeat while selection crossfades', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    Widget row(bool selected) => _app(
      BottomBarItems(
        children: [
          BottomBarItem(
            selected: selected,
            icon: const Icon(Icons.home_outlined, semanticLabel: 'Home'),
            selectedIcon: const Icon(
              Icons.home,
              semanticLabel: 'Selected Home',
            ),
          ),
        ],
      ),
    );
    await tester.pumpWidget(row(false));
    await tester.pumpWidget(row(true));
    await tester.pump(const Duration(milliseconds: 50));
    final labels = semanticsLabels(tester).toList();
    expect(labels, hasLength(1));
    expect(RegExp('Home').allMatches(labels.single), hasLength(1));
    expect(labels.single, contains('Selected Home'));
    semantics.dispose();
  });
  testWidgets(
    'custom label semantics stay isolated across indicators and rails',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        for (final indicator in const [
          BottomBarIndicator.pill(),
          BottomBarIndicator.tint(),
          BottomBarIndicator.underline(),
          BottomBarIndicator.container(),
        ]) {
          for (final behavior in BottomBarLabelBehavior.values) {
            for (final direction in Axis.values) {
              for (final textDirection in TextDirection.values) {
                Widget row(int selected) => _app(
                  Directionality(
                    textDirection: textDirection,
                    child: BottomBarItems(
                      direction: direction,
                      selectedIndex: selected,
                      onSelected: (_) {},
                      indicator: indicator,
                      labelBehavior: behavior,
                      centerAction: BottomBarCenterAction(
                        icon: const Icon(Icons.add),
                        semanticLabel: 'Create',
                        onPressed: () {},
                      ),
                      children: [
                        BottomBarItem(
                          icon: Icon(Icons.home, semanticLabel: 'Home'),
                          label: Semantics(
                            label: 'First custom label',
                            child: SizedBox(height: 12),
                          ),
                        ),
                        BottomBarItem(
                          icon: Icon(Icons.inbox, semanticLabel: 'Inbox'),
                          label: Semantics(
                            label: 'Second custom label',
                            child: SizedBox(height: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                await tester.pumpWidget(row(0));
                await tester.pumpAndSettle();
                await tester.pumpWidget(row(1));
                await tester.pump(const Duration(milliseconds: 50));
                final labels = semanticsLabels(tester).toList();
                expect(labels.where((l) => l.contains('Home')), hasLength(1));
                expect(labels.where((l) => l.contains('Inbox')), hasLength(1));
                expect(labels.where((l) => l.contains('Create')), ['Create']);
                for (final label in labels) {
                  expect(
                    RegExp('Home').allMatches(label).length,
                    lessThanOrEqualTo(1),
                  );
                  expect(
                    RegExp('Inbox').allMatches(label).length,
                    lessThanOrEqualTo(1),
                  );
                  expect(
                    label.contains('Home') && label.contains('Inbox'),
                    isFalse,
                  );
                }
                expect(tester.takeException(), isNull);
              }
            }
          }
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'tab counts refresh after removing and reordering keyed children',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        Widget row(List<String> names) => _app(
          BottomBarItems(
            children: [
              for (final name in names)
                BottomBarItem(
                  key: ValueKey(name),
                  icon: const Icon(Icons.home),
                  label: Text(name),
                ),
            ],
          ),
        );
        await tester.pumpWidget(row(['Home', 'Inbox', 'Saved']));
        await tester.pumpWidget(row(['Saved', 'Home']));
        expect(semanticsLabels(tester), [
          'Saved, Tab 1 of 2',
          'Home, Tab 2 of 2',
        ]);
        await tester.pumpWidget(row(['Home']));
        expect(semanticsLabels(tester), ['Home, Tab 1 of 1']);
        await tester.pumpWidget(row([]));
        expect(semanticsLabels(tester), isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
