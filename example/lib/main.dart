import 'package:cached_image/cached_image.dart';
import 'package:flutter/material.dart';
import 'urls.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedStorage.init();
  runApp(const MaterialApp(
    home: AppScreen(),
  ));
}

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ));
              },
              child: const Text('Open'),
            ),
            ElevatedButton(
              onPressed: () async {
                await CachedImage.clear();
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    CachedImage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: ListView.builder(
          itemCount: urls.length,
          itemBuilder: (context, i) => CachedImage(urls[i]),
        ));
  }
}
