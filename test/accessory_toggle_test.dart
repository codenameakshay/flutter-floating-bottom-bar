import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('adding and removing the accessory keeps every piece mounted', (
    tester,
  ) async {
    final mounts = <String>[];
    late StateSetter setOuter;
    var showAccessory = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return BottomBar(
              layout: const BottomBarLayout(width: 360),
              leading: _Probe('leading', mounts),
              trailing: _Probe('trailing', mounts),
              accessory: showAccessory
                  ? const SizedBox(height: 56, child: Text('Now playing'))
                  : null,
              body: const SizedBox.expand(),
              child: BottomBarItems(
                selectedIndex: 0,
                children: [
                  BottomBarItem(
                    icon: _Probe('item', mounts),
                    label: const Text('Home'),
                  ),
                  const BottomBarItem(
                    icon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    const mountedOnce = ['item', 'leading', 'trailing'];
    expect([...mounts]..sort(), mountedOnce);

    setOuter(() => showAccessory = true);
    await tester.pumpAndSettle();
    expect(find.text('Now playing'), findsOneWidget);
    expect(
      [...mounts]..sort(),
      mountedOnce,
      reason: 'a mini player that appears must not remount the bar',
    );

    setOuter(() => showAccessory = false);
    await tester.pumpAndSettle();
    expect(find.text('Now playing'), findsNothing);
    expect([...mounts]..sort(), mountedOnce);
  });
}

class _Probe extends StatefulWidget {
  const _Probe(this.name, this.mounts);

  final String name;
  final List<String> mounts;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.mounts.add(widget.name);
  }

  @override
  Widget build(BuildContext context) => const Icon(Icons.circle);
}
