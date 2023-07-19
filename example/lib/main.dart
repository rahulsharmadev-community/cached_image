import 'package:cached_image/cached_image.dart';
import 'package:flutter/material.dart';

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
      backgroundColor: Colors.amberAccent,
      appBar: AppBar(),
      body: CachedImage(
        'https://images.pexels.com/photos/235222/pexels-photo-235222.jpeg',
        fit: BoxFit.fitWidth,
        loadingBuilder: (ctx, p1) => Container(
          width: 323,
          height: 440,
          color: Colors.red,
          child: Text(
            '${p1.downloadedBytes} <--',
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
