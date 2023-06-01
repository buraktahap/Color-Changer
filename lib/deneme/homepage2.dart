import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class MyHomePage2 extends StatefulWidget {
  const MyHomePage2({super.key});

  @override
  State<MyHomePage2> createState() => _MyHomePage2State();
}

class _MyHomePage2State extends State<MyHomePage2> {
  img.Image? _sourceImage;
  img.Image? _paletteImage;
  Uint8List? _generatedImageData;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          if (_sourceImage != null) ...[
            const Text('Source Image:'),
            Image.memory(img.encodePng(_sourceImage!) as Uint8List),
          ],
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: _loadSourceImage,
            child: const Center(child: Text('Load Source Image')),
          ),
          if (_paletteImage != null) ...[
            const Text('Palette Image:'),
            Image.memory(img.encodePng(_paletteImage!) as Uint8List),
          ],
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: _loadPaletteImage,
            child: const Center(child: Text('Load Palette Image')),
          ),
          if (_sourceImage != null && _paletteImage != null) ...[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _generateImage(_sourceImage!, _paletteImage!),
              child: const Center(child: Text('Generate Image')),
            ),
          ],
          if (_generatedImageData != null) ...[
            const Text('Generated Image:'),
            Image.memory(_generatedImageData!),
          ],
        ],
      ),
    );
  }

  Future<void> _loadSourceImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final sourceImage = img.decodeImage(bytes);
      if (sourceImage != null) {
        final resizedImage = _resizeImage(
            sourceImage, 800, 800); // Adjust these values as needed
        setState(() {
          _sourceImage = resizedImage;
        });
      }
    }
  }

  Future<void> _loadPaletteImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final paletteImage = img.decodeImage(bytes);
      if (paletteImage != null) {
        final resizedImage = _resizeImage(
            paletteImage, 800, 800); // Adjust these values as needed
        setState(() {
          _paletteImage = resizedImage;
        });
      }
    }
  }

  Future<void> _generateImage(
      img.Image sourceImage, img.Image paletteImage) async {
    final paletteColors = _getPaletteColors(paletteImage);
    final tasks = _createTasks(sourceImage, paletteColors);
    final generatedImages =
        await Future.wait(tasks.map((task) => compute(_processTask, task)));
    final combinedImage = _combineGeneratedImages(
        generatedImages, sourceImage.width, sourceImage.height);

    setState(() {
      _generatedImageData = Uint8List.fromList(img.encodePng(combinedImage));
    });
  }

  List<_Task> _createTasks(img.Image sourceImage, List<int> paletteColors) {
    const int numTasks =
        1; // Adjust this value based on the number of cores in your device
    final int numRows = (sourceImage.height / numTasks).ceil();
    final List<_Task> tasks = [];

    for (int i = 0; i < numTasks; i++) {
      final int startY = i * numRows;
      final int endY =
          i == numTasks - 1 ? sourceImage.height : (i + 1) * numRows;
      tasks.add(_Task(sourceImage, paletteColors, startY, endY));
    }

    return tasks;
  }

  img.Image _resizeImage(img.Image image, int maxWidth, int maxHeight) {
    double scaleFactor = 1.0;

    if (image.width > maxWidth) {
      scaleFactor = maxWidth / image.width;
    }
    if (image.height * scaleFactor > maxHeight) {
      scaleFactor = maxHeight / image.height;
    }

    return img.copyResize(image,
        width: (image.width * scaleFactor).toInt(),
        height: (image.height * scaleFactor).toInt());
  }

  img.Image _combineGeneratedImages(
      List<img.Image> images, int width, int height) {
    final combinedImage = img.Image(width, height);

    for (int i = 0; i < images.length; i++) {
      final part = images[i];
      final int startY = i * part.height;
      img.copyInto(combinedImage, part, dstY: startY);
    }

    return combinedImage;
  }

  Future<img.Image> _processTask(_Task task) async {
    final generatedImage = img.Image.from(task.sourceImage);
    for (int y = task.startY; y < task.endY; y++) {
      for (int x = 0; x < generatedImage.width; x++) {
        final pixelColor = generatedImage.getPixel(x, y);
        final closestColor = _findClosestColor(task.paletteColors, pixelColor);
        generatedImage.setPixel(x, y, closestColor);
      }
    }

    return img.copyCrop(generatedImage, 0, task.startY, generatedImage.width,
        task.endY - task.startY);
  }

  List<int> _getPaletteColors(img.Image paletteImage) {
    final List<int> colors = [];
    for (int y = 0; y < paletteImage.height; y++) {
      for (int x = 0; x < paletteImage.width; x++) {
        final color = paletteImage.getPixel(x, y);
        if (!colors.contains(color)) {
          colors.add(color);
        }
      }
    }

    return colors;
  }

  int _findClosestColor(List<int> paletteColors, int pixelColor) {
    int minDistance = 255 * 3 + 1;
    int closestColor = 0;
    for (final paletteColor in paletteColors) {
      final distance = _colorDistance(pixelColor, paletteColor);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = paletteColor;
      }
    }

    return closestColor;
  }

  int _colorDistance(int color1, int color2) {
    final r1 = img.getRed(color1);
    final g1 = img.getGreen(color1);
    final b1 = img.getBlue(color1);

    final r2 = img.getRed(color2);
    final g2 = img.getGreen(color2);
    final b2 = img.getBlue(color2);

    final rDiff = (r1 - r2).abs();
    final gDiff = (g1 - g2).abs();
    final bDiff = (b1 - b2).abs();

    return rDiff + gDiff + bDiff;
  }
}

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Image Color Palette'),
        ),
        body: const MyHomePage2(),
      ),
    ),
  );
}

class _Task {
  final img.Image sourceImage;
  final List<int> paletteColors;
  final int startY;
  final int endY;

  _Task(this.sourceImage, this.paletteColors, this.startY, this.endY);
}
