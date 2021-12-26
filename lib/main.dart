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
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 10,
              child: Container(
                height: 46,
                child: TextField(
                  style: Theme.of(context).textTheme.subtitle2,
                  maxLines: 1,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: Theme.of(context).accentColor,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.search),
                    contentPadding: const EdgeInsets.all(16),
                    hintStyle: Theme.of(context).textTheme.subtitle2,
                    hintText: 'Search...',
                    border: InputBorder.none,
                    labelStyle: Theme.of(context).textTheme.subtitle2,
                  ),
                ),
              ),
            ),
          ),
          fit: StackFit.expand,
          borderRadius: BorderRadius.circular(12),
          duration: Duration(milliseconds: 300),
          curve: Curves.decelerate,
          showIcon: false,
          width: MediaQuery.of(context).size.width - 32,
          barColor: Colors.transparent,
          start: 2,
          end: 0,
          bottom: 10,
          alignment: Alignment.bottomCenter,
          body: (context, controller) => InfiniteListPage(
              controller: controller, color: Colors.blueAccent),
        ),
      ),
    );
  }
}
