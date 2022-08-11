import 'package:flutter/material.dart';
import 'package:cached_image/cached_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: ListView(children: [
          CachedImage(
              'https://feeds.abplive.com/onecms/images/uploaded-images/2022/08/10/27240f4364233ba0eb1c7266b3c86622166011849425819_original.jpg?impolicy=abp_cdn&imwidth=720'),
          Container(height: 50, width: double.maxFinite, color: Colors.amber),
          CachedImage(
              'https://feeds.abplive.com/onecms/images/uploaded-images/2022/08/10/347342e0f76ed96b6a6f3d6eed36cd3d1660125716398272_original.jpg?impolicy=abp_cdn&imwidth=720')
        ]
            // This trailing comma makes auto-formatting nicer for build methods.
            ));
  }
}
