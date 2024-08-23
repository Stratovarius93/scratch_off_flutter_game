import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ScratchStatus { keepScratching, almostThere, youWon, start }

extension ScratchStatusExtension on ScratchStatus {
  String get name {
    switch (this) {
      case ScratchStatus.keepScratching:
        return 'Keep scratching';
      case ScratchStatus.almostThere:
        return 'Almost there';
      case ScratchStatus.youWon:
        return 'You won!';
      case ScratchStatus.start:
        return 'Start';
    }
  }
}

class ScratchCard extends StatefulWidget {
  final String backgroundImageUrl;
  final String overlayImageUrl;
  final void Function(ScratchStatus) onStatusChanged;
  final double size;
  final ScratchCardController controller;
  final BorderRadius borderRadius;
  const ScratchCard({
    Key? key,
    required this.backgroundImageUrl,
    required this.overlayImageUrl,
    required this.onStatusChanged,
    this.size = 300.0,
    required this.controller,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) : super(key: key);

  @override
  State<ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<ScratchCard> {
  ui.Image? overlayImage;
  late Size size;
  final scratchPath = Path();
  double scratchPercentage = 0.0;
  ScratchStatus status = ScratchStatus.start;
  Future<List<ui.Image>>? imagesFuture;

  @override
  void initState() {
    super.initState();
    size = Size(widget.size, widget.size);
    imagesFuture = loadImages();

    loadOverlayImage();
    widget.controller.statusStream.listen((status) {
      if (status == ScratchStatus.start) {
        reset();
      }
    });
  }

  Future<ui.Image> loadImage(String url) async {
    final imageProvider = NetworkImage(url);
    final completer = Completer<ui.Image>();
    final stream = imageProvider.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener((ImageInfo image, bool synchronousCall) {
        completer.complete(image.image);
      }),
    );
    return completer.future;
  }

  Future<List<ui.Image>> loadImages() async {
    final overlayImageFuture = loadImage(widget.overlayImageUrl);
    final backgroundImageFuture = loadImage(widget.backgroundImageUrl);
    return Future.wait([overlayImageFuture, backgroundImageFuture]);
  }

  Future<void> loadOverlayImage() async {
    final overlayImageProvider = NetworkImage(widget.overlayImageUrl);
    final completer = Completer<ui.Image>();
    final stream = overlayImageProvider.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener((ImageInfo image, bool synchronousCall) {
        completer.complete(image.image);
      }),
    );
    final uiImage = await completer.future;
    setState(() {
      overlayImage = uiImage;
    });
  }

  void updateScratchPath(Offset position) {
    setState(() {
      scratchPath.addOval(Rect.fromCircle(center: position, radius: 20));
      scratchPercentage = getScratchPercentage();
    });
  }

  double getScratchPercentage() {
    final scratchArea = scratchPath.computeMetrics().fold(
          0.0,
          (double previousValue, PathMetric metric) =>
              previousValue + metric.length,
        );
    final totalArea = widget.size * widget.size;
    status = getStatus(scratchArea / totalArea);
    if (status != ScratchStatus.youWon) {
      HapticFeedback.vibrate();
    }
    widget.onStatusChanged(status);
    return scratchArea / totalArea;
  }

  ScratchStatus getStatus(double percentage) {
    if (percentage < 0.1) {
      return ScratchStatus.keepScratching;
    } else if (percentage < 0.3) {
      return ScratchStatus.almostThere;
    } else {
      return ScratchStatus.youWon;
    }
  }

  void reset() {
    setState(() {
      scratchPath.reset();
      scratchPercentage = 0.0;
      status = ScratchStatus.start;
      widget.onStatusChanged(status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ui.Image>>(
      future: imagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                borderRadius: widget.borderRadius,
              ),
              child: const Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                borderRadius: widget.borderRadius,
              ),
              child: Center(
                  child: Text('Error loading images: ${snapshot.error}')));
        } else if (snapshot.hasData) {
          return buildScratchCardGame(snapshot.data![0], snapshot.data![1]);
        } else {
          return Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                borderRadius: widget.borderRadius,
              ),
              child: const Center(child: Text('Unexpected error')));
        }
      },
    );
  }

  Widget buildScratchCardGame(ui.Image overlayImage, ui.Image backgroundImage) {
    return Center(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            Image.network(
              widget.backgroundImageUrl,
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
            ),
            // if (overlayImage != null)
            GestureDetector(
              onPanUpdate: (details) {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                Offset localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                Offset adjustedPosition = Offset(
                  localPosition.dx - (renderBox.size.width - widget.size) / 2,
                  localPosition.dy - (renderBox.size.height - widget.size) / 2,
                );
                updateScratchPath(adjustedPosition);
              },
              child: CustomPaint(
                size: size,
                painter: ScratchPainter(scratchPath, overlayImage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScratchPainter extends CustomPainter {
  final Path scratchPath;
  final ui.Image overlayImage;

  ScratchPainter(this.scratchPath, this.overlayImage);
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Rect imageRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(imageRect, paint);
    canvas.drawImageRect(
      overlayImage,
      Rect.fromLTWH(
          0, 0, overlayImage.width.toDouble(), overlayImage.height.toDouble()),
      imageRect,
      paint,
    );
    Path borderPath = Path.from(scratchPath);
    Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawPath(borderPath, borderPaint);
    Paint clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;
    canvas.drawPath(scratchPath, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ScratchCardController {
  final _statusStreamController = StreamController<ScratchStatus>.broadcast();

  ScratchStatus _status = ScratchStatus.start;

  Stream<ScratchStatus> get statusStream => _statusStreamController.stream;

  ScratchStatus get status => _status;

  void reset() {
    _status = ScratchStatus.start;
    _statusStreamController.add(_status);
  }

  void updateStatus(ScratchStatus newStatus) {
    if (newStatus != _status) {
      _status = newStatus;
      _statusStreamController.add(_status);
    }
  }

  void dispose() {
    _statusStreamController.close();
  }
}
