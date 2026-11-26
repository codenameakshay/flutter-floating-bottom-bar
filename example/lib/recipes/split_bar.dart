import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class SplitBarRecipe extends StatefulWidget {
  const SplitBarRecipe({super.key});

  @override
  State<SplitBarRecipe> createState() => _SplitBarRecipeState();
}

class _SplitBarRecipeState extends State<SplitBarRecipe> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split bar')),
      body: BottomBar(
        theme: BottomBarThemeData.glass(),
        layout: const BottomBarLayout.adaptive(
          maxWidth: 480,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        leading: IconButton(
          tooltip: 'Profile',
          onPressed: () {},
          icon: const CircleAvatar(radius: 16, child: Text('JD')),
        ),
        trailing: IconButton(
          tooltip: 'Search',
          onPressed: () {},
          icon: const Icon(Icons.search),
        ),
        body: Builder(
          builder: (context) => ValueListenableBuilder<double>(
            valueListenable: BottomBarScope.of(context).barHeight,
            builder: (context, barHeight, _) => GridView.builder(
              padding: EdgeInsets.fromLTRB(2, 2, 2, barHeight),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 60,
              itemBuilder: (context, i) => ColoredBox(
                color: Colors.primaries[i % Colors.primaries.length].shade300,
              ),
            ),
          ),
        ),
        child: BottomBarItems(
          selectedIndex: _index,
          onSelected: (i) => setState(() => _index = i),
          children: const [
            BottomBarItem(icon: Icon(Icons.photo), label: Text('Library')),
            BottomBarItem(icon: Icon(Icons.collections), label: Text('Albums')),
            BottomBarItem(icon: Icon(Icons.favorite), label: Text('For you')),
          ],
        ),
      ),
    );
  }
}
