import 'package:floating_bar/provider/inherited_data_provider.dart';
import 'package:flutter/material.dart';

class InfiniteListPage extends StatelessWidget {
  final Color color;
  const InfiniteListPage({required this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScrollController controller =
        InheritedDataProvider.of(context).scrollController;
    return ListView.builder(
      controller: controller,
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {},
          tileColor: color,
          title: Text("$index"),
        );
      },
    );
  }
}
