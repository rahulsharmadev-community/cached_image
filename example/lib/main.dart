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
  var images = List.generate(10, (i) => urls[i]);
  late ScrollController controller;
  @override
  void initState() {
    super.initState();
    controller = ScrollController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool isGrid = true;

  @override
  Widget build(BuildContext context) {
    print('Rebuild__Screen');
    return Scaffold(
        backgroundColor: Colors.amberAccent,
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                onPressed: () {
                  setState(() => images = [urls[images.length], ...images]);
                },
                icon: const Icon(Icons.add)),
            IconButton(
                onPressed: () {
                  setState(() => images.removeLast());
                },
                icon: const Icon(Icons.minimize))
          ],
        ),
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () => setState(() => isGrid = !isGrid),
                icon: Icon(isGrid ? Icons.list : Icons.grid_on))
          ],
        ),
        body: isGrid
            ? GridView.builder(
                itemCount: images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemBuilder: (ctx, i) => DisplayImage(i: i, isGrid: true))
            : ListView.builder(
                reverse: true,
                controller: controller,
                itemCount: images.length,
                itemBuilder: (ctx, i) => List<Widget>.generate(
                    images.length, (i) => itemWidget(i))[i],
              ));
  }

  Widget itemWidget(int i) => CustomCard(i: i, isGrid: isGrid);
}

class CustomCard extends StatelessWidget {
  final int i;
  final bool isGrid;
  const CustomCard({
    super.key,
    required this.i,
    required this.isGrid,
  });

  @override
  Widget build(BuildContext context) {
    var width2 = MediaQuery.of(context).size.width * 0.6;
    return Row(
      mainAxisAlignment:
          i % 3 == 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        SizedBox(width: width2, child: DisplayImage(i: i, isGrid: isGrid)),
      ],
    );
  }
}

class DisplayImage extends StatelessWidget {
  const DisplayImage({
    super.key,
    required this.i,
    required this.isGrid,
  });

  final int i;
  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => Material(
                  type: MaterialType.transparency,
                  child: SizedBox.expand(
                      child: InteractiveViewer(
                    maxScale: 5,
                    child: Hero(tag: urls[i], child: CachedImage(urls[i])),
                  )),
                )));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: urls[i],
            child: CachedImage(
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
            ),
          ),
          Text(
            urls[i],
            maxLines: 1,
            overflow: TextOverflow.clip,
          )
        ],
      ),
    );
  }
}
