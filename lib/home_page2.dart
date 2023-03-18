import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';

class MyHomePage2 extends StatefulWidget {
  const MyHomePage2({Key? key}) : super(key: key);

  @override
  State<MyHomePage2> createState() => _MyHomePage2State();
}

class _MyHomePage2State extends State<MyHomePage2> {
  File? _firstImage;
  File? _secondImage;
  PaletteGenerator? _palette1;
  PaletteGenerator? _palette2;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _generatedImageData;
  bool _isLoading = false;
  late List<List<List<int>>> _colorMap;

  Future<void> _pickFirstImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _firstImage = File(pickedFile.path);
      });
      await _generatePalette(true);
    }
  }

  Future<void> _pickSecondImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _secondImage = File(pickedFile.path);
      });
      await _generatePalette(false);
    }
  }

  Future<void> _generatePalette(bool isFirstImage) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final imageProvider =
          FileImage(isFirstImage ? _firstImage! : _secondImage!);
      final paletteGenerator =
          await PaletteGenerator.fromImageProvider(imageProvider);

      setState(() {
        if (isFirstImage) {
          _palette1 = paletteGenerator;
        } else {
          _palette2 = paletteGenerator;
        }
        if (_palette1 != null && _palette2 != null) {
          _colorMap = _computeColorMap(_palette1!, _palette2!);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating palette: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Computes the Euclidean distance between two colors in Lab color space.
  double _colorDistance(List<int> color1, List<int> color2) {
    final lDiff = color1[0] - color2[0];
    final aDiff = color1[1] - color2[1];
    final bDiff = color1[2] - color2[2];
    return sqrt(lDiff * lDiff + aDiff * aDiff + bDiff * bDiff);
  }

  List<List<List<int>>> _computeColorMap(
      PaletteGenerator palette1, PaletteGenerator palette2) {
    final colors1 = palette1.colors.toList();
    final colors2 = palette2.colors.toList();

    final colorMap = List.generate(
      256,
      (i) => List.generate(
        256,
        (j) => List.filled(256, 0),
      ),
    );

    for (int r = 0; r < 256; r++) {
      for (int g = 0; g < 256; g++) {
        for (int b = 0; b < 256; b++) {
          int closestColorIndex = 0;
          double closestDistance = double.infinity;

          for (int i = 0; i < colors1.length; i++) {
            final distance = _colorDistance(
                _rgbToLab(colors1[i]), _rgbToLab(Color.fromARGB(255, r, g, b)));
            if (distance < closestDistance) {
              closestDistance = distance;
              closestColorIndex = i;
            }
          }

          final closestColor = colors1[closestColorIndex];
          colorMap[r][g][b] = img.getColor(
              closestColor.red, closestColor.green, closestColor.blue);
        }
      }
    }

    return colorMap;
  }

  img.Image _remapColors(img.Image source, List<List<List<int>>> colorMap) {
    final newImage = img.Image(source.width, source.height);

// Remap the colors of each pixel in the source image to the closest
// color in the target palette.
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final pixelColor = source.getPixel(x, y);
        final r = img.getRed(pixelColor);
        final g = img.getGreen(pixelColor);
        final b = img.getBlue(pixelColor);
        newImage.setPixel(x, y, colorMap[r][g][b]);
      }
    }

    return newImage;
  }

  Future<void> _generateNewImage() async {
    if (_firstImage == null ||
        _secondImage == null ||
        _palette1 == null ||
        _palette2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both images and generate palettes.')),
      );
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });

      final image2 = img.decodeImage(await _secondImage!.readAsBytes());

      final transformedImage = _remapColors(image2!, _colorMap);

      final directory = await getApplicationDocumentsDirectory();
      final generatedImagePath = '${directory.path}/generated_image.png';
      File(generatedImagePath)
          .writeAsBytesSync(img.encodePng(transformedImage));

      setState(() {
        _generatedImageData =
            Uint8List.fromList(img.encodePng(transformedImage));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading == true
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                TextButton(
                  onPressed: _pickFirstImage,
                  child: const Text('Select First Image'),
                ),
                if (_firstImage != null) Image.file(_firstImage!),
                if (_palette1 != null) ...[
                  const Text('Color Palette 1:'),
                  Wrap(
                    children: _palette1!.colors.map((color) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                TextButton(
                  onPressed: _pickSecondImage,
                  child: const Text('Select Second Image'),
                ),
                if (_secondImage != null) Image.file(_secondImage!),
                if (_palette2 != null) ...[
                  const Text('Color Palette 2:'),
                  Wrap(
                    children: _palette2!.colors.map((color) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                TextButton(
                  onPressed: () => _generateNewImage(),
                  child: const Text('Generate'),
                ),
                if (_generatedImageData != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(_generatedImageData!),
                  ),
              ],
            ),
          );
  }

// Converts an RGB color to a Lab color.
  List<int> _rgbToLab(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final x = 0.4124 * r + 0.3576 * g + 0.1805 * b;
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    final z = 0.0193 * r + 0.1192 * g + 0.9505 * b;

    const xRef = 0.95047;
    const yRef = 1.0;
    const zRef = 1.08883;

    const epsilon = 0.008856;
    const kappa = 903.3;

    final xr = x / xRef;
    final yr = y / yRef;
    final zr = z / zRef;

    final fx = xr > epsilon ? pow(xr, 1 / 3) : (kappa * xr + 16) / 116;
    final fy = yr > epsilon ? pow(yr, 1 / 3) : (kappa * yr + 16) / 116;
    final fz = zr > epsilon ? pow(zr, 1 / 3) : (kappa * zr + 16) / 116;

    final l = 116 * fy - 16;
    final a = 500 * (fx - fy);
    final c = 200 * (fy - fz);

    return [l, a, c].map((e) => e.toInt()).toList();
  }
}
