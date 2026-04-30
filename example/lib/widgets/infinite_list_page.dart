import 'package:flutter/material.dart';

class InfiniteListPage extends StatelessWidget {
  final Color color;
  const InfiniteListPage({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) =>
          ListTile(onTap: () {}, tileColor: color, title: Text("$index")),
    );
  }
}
