import 'package:flutter/material.dart';
import 'package:test_scratch/scratch/scratch.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with AutomaticKeepAliveClientMixin {
  String status = 'Start';
  final backgroundImageUrl =
      'https://media.istockphoto.com/id/1361394182/photo/funny-british-shorthair-cat-portrait-looking-shocked-or-surprised.webp?b=1&s=170667a&w=0&k=20&c=nOa1R7PGaqOaQscx10FpA5ZNenMeDfs-k6VgmmuY4cc=';
  final overlayImageUrl =
      'https://pics.craiyon.com/2023-09-09/83616b1b2cc24d309022ca230e84912b.webp';

  ScratchCardController scratchCardController = ScratchCardController();

  @override
  void dispose() {
    scratchCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scratch Card'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          ScratchCard(
              controller: scratchCardController,
              backgroundImageUrl: backgroundImageUrl,
              overlayImageUrl: overlayImageUrl,
              onStatusChanged: (value) {
                setState(() {
                  status = value.name;
                });
              }),
          const SizedBox(height: 20),
          Text('Status: $status'),
          ElevatedButton(
            onPressed: () {
              setState(() {
                scratchCardController.reset();
              });
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
