import 'package:example/urls.dart';
import 'package:cached_image/cached_image.dart';
import 'package:flutter/material.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  CachedImage.isolate = true;
  CachedImage.initialize('Class A');
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => CachedImage.clearAll('Class A'),
                child: const Text('Delete Class A'),
              ),
              ElevatedButton(
                onPressed: () => CachedImage.clearAll('Class B'),
                child: const Text('Delete Class B'),
              ),
              ElevatedButton(
                onPressed: () => CachedImage.clearAll(''),
                child: const Text('Delete All'),
              ),
            ],
          ),
        ],
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

  bool isGrid = true;

  @override
  Widget build(BuildContext context) {
    final widgets = List<Widget>.generate(urls.length, (i) => itemWidget(i));

    return Scaffold(
        backgroundColor: Colors.amberAccent,
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () => setState(() => isGrid = !isGrid),
                icon: Icon(isGrid ? Icons.list : Icons.grid_on))
          ],
        ),
        body: isGrid
            ? GridView.builder(
                itemCount: widgets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemBuilder: (ctx, i) => widgets[i])
            : ListView.builder(
                itemCount: widgets.length,
                itemBuilder: (ctx, i) => widgets[i],
              ));
  }

  CachedImage itemWidget(int i) {
    return CachedImage(
      urls[i],
      fit: BoxFit.cover,
      location: i % 2 == 0 ? 'Class B' : null,
      loadingBuilder: (ctx, value) => ValueListenableBuilder(
        valueListenable: value.progressPercentage,
        builder: (context, value, child) => Stack(
          alignment: Alignment.center,
          children: [
            isGrid
                ? SizedBox.square(
                    dimension: 60,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: CircularProgressIndicator.adaptive(
                        value: value,
                        semanticsLabel: value.toString(),
                        semanticsValue: value.toString(),
                      ),
                    ),
                  )
                : LinearProgressIndicator(
                    value: value,
                    minHeight: 42,
                    semanticsLabel: value.toString(),
                    semanticsValue: value.toString(),
                  ),
            Text(
              '${value * 100}%',
              style: TextStyle(
                fontSize: isGrid ? 16 : 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
