import 'dart:ui';
import 'package:flutter/material.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({Key? key}) : super(key: key);

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  final scratchPath = Path();
  double scratchPercentage = 0.0;
  String status = 'Start';

  void updateScratchPath(Offset position) {
    setState(() {
      scratchPath.addOval(Rect.fromCircle(center: position, radius: 20));
      scratchPercentage =
          getScratchPercentage(); // Update percentage only on scratch
    });
  }

  double getScratchPercentage() {
    final scratchArea = scratchPath.computeMetrics().fold(
          0.0,
          (double previousValue, PathMetric metric) =>
              previousValue + metric.length,
        );
    const totalArea = 300 * 300;
    status = getStatus(scratchArea / totalArea);
    return scratchArea / totalArea;
  }

  String getStatus(double percentage) {
    if (percentage < 0.2) {
      return 'Keep scratching';
    } else if (percentage < 0.6) {
      return 'Almost there';
    } else {
      return 'You won!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scratch Card'),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                Image.network(
                  'https://media.istockphoto.com/id/1361394182/photo/funny-british-shorthair-cat-portrait-looking-shocked-or-surprised.webp?b=1&s=170667a&w=0&k=20&c=nOa1R7PGaqOaQscx10FpA5ZNenMeDfs-k6VgmmuY4cc=',
                  fit: BoxFit.cover,
                  width: 300,
                  height: 300,
                ),
                GestureDetector(
                  onPanUpdate: (details) {
                    RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    Offset localPosition =
                        renderBox.globalToLocal(details.localPosition);
                    updateScratchPath(localPosition);
                  },
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: ScratchPainter(scratchPath, scratchPercentage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Status: $status'),
            // Restart button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  scratchPath.reset();
                  scratchPercentage = 0.0;
                  status = 'Start';
                });
              },
              child: const Text('Restart'),
            ),
          ],
        ),
      ),
    );
  }
}

class ScratchPainter extends CustomPainter {
  final Path scratchPath;
  final double scratchPercentage;

  ScratchPainter(this.scratchPath, this.scratchPercentage);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    Paint clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;
    canvas.drawPath(scratchPath, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
