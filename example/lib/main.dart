import 'package:example/urls.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_image/cached_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  CachedImage.isolate = true;
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getTemporaryDirectory(),
  );

  runApp(const FlutterApp());
}

class FlutterApp extends StatelessWidget {
  const FlutterApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: AppScreen());
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
              onPressed: () => CachedImage.clear(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.amberAccent,
        appBar: AppBar(),
        body: GridView.builder(
          itemCount: urls.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 16 / 9,
          ),
          itemBuilder: (ctx, i) => CachedImage(
            urls[i],
            loadingBuilder: (ctx, value) => ValueListenableBuilder(
              valueListenable: value.progressPercentage,
              builder: (context, value, child) => Text('$value'),
            ),
          ),
        ));
  }
}
