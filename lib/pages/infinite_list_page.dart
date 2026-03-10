import 'package:flutter/material.dart';

class InfiniteListPage extends StatelessWidget {
  final Color color;
  final ScrollController controller;
  const InfiniteListPage(
      {super.key, required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      // reverse: true,
      itemBuilder: (context, index) {
        return ListTile(onTap: () {}, tileColor: color, title: Text("$index"));
      },
    );
  }
}
