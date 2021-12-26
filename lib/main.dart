import 'package:floating_bottom_bar/pages/infinite_list_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Floating Bottom Bar Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Flutter Floating Bottom Bar Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.black,
        ),
        body: BottomBar(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "This is the floating widget",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: (context, controller) =>
              InfiniteListPage(controller: controller, color: Colors.blue),
        ),
      ),
    );
  }
}
