import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class ScrollUnderRecipe extends StatefulWidget {
  const ScrollUnderRecipe({super.key});

  @override
  State<ScrollUnderRecipe> createState() => _ScrollUnderRecipeState();
}

class _ScrollUnderRecipeState extends State<ScrollUnderRecipe> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        theme: BottomBarThemeData.glass(),
        body: Builder(
          builder: (context) => ValueListenableBuilder<double>(
            valueListenable: BottomBarScope.of(context).barHeight,
            builder: (context, barHeight, _) => CustomScrollView(
              slivers: [
                const SliverAppBar.medium(title: Text('Scroll under')),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: barHeight),
                  sliver: SliverList.builder(
                    itemCount: 40,
                    itemBuilder: (context, i) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.primaries[i % Colors.primaries.length],
                      ),
                      title: Text('Row ${i + 1}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: BottomBarSwitcher(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('40 rows')),
                    IconButton(
                      tooltip: _expanded ? 'Hide filters' : 'Show filters',
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(_expanded ? Icons.expand_more : Icons.tune),
                    ),
                  ],
                ),
                if (_expanded)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 12, bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Unread')),
                        Chip(label: Text('Starred')),
                        Chip(label: Text('Files')),
                        Chip(label: Text('This week')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
