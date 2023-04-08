import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
//import math as math;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _firstImage;
  File? _secondImage;
  PaletteGenerator? _palette1;
  PaletteGenerator? _palette2;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _generatedImageData;
  bool _isLoading = false;
  String? _resultImageBase64;

  Future<File> _convertHeicToPng(File heicFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final pngFilePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    final pngFile = File(pngFilePath);
    final compressedData = await FlutterImageCompress.compressWithFile(
      heicFile.absolute.path,
      minWidth: 800,
      minHeight: 600,
      quality: 90,
      rotate: 0,
      format: CompressFormat.png,
    );
    await pngFile.writeAsBytes(compressedData!);
    return pngFile;
  }

  Future<File> _convertHeifToPng(File heifFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final pngFilePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    final pngFile = File(pngFilePath);
    final compressedData = await FlutterImageCompress.compressWithFile(
      heifFile.absolute.path,
      minWidth: 800,
      minHeight: 600,
      quality: 90,
      rotate: 0,
      format: CompressFormat.png,
    );
    await pngFile.writeAsBytes(compressedData!);
    return pngFile;
  }

  Future<String> applyColorTransfer(File sourceImage, File targetImage) async {
    String apiUrl = 'http://192.168.0.25:5002/color_transfer';
    String sourceBase64 = base64Encode(sourceImage.readAsBytesSync());
    String targetBase64 = base64Encode(targetImage.readAsBytesSync());

    final response = await http.post(
      Uri.parse(apiUrl),
      body: {'source_image': sourceBase64, 'target_image': targetBase64},
    );

    return response.body;
  }

  Future<void> _pickImage(bool isFirstImage) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (pickedFile.path.toLowerCase().endsWith('.heic')) {
        imageFile = await _convertHeicToPng(imageFile);
      }
      if (pickedFile.path.toLowerCase().endsWith('.heif')) {
        imageFile = await _convertHeifToPng(imageFile);
      }
      setState(() {
        isFirstImage == true
            ? _firstImage = imageFile
            : _secondImage = imageFile;
      });
      await _generatePalette(isFirstImage);
    }
  }

  List<Color> _sortPaletteByHue(List<Color> colors) {
    return colors
      ..sort((a, b) =>
          HslColor.fromColor(a).hue.compareTo(HslColor.fromColor(b).hue));
  }

  Future<void> _generatePalette(bool isFirstImage) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final imageProvider =
          isFirstImage ? FileImage(_firstImage!) : FileImage(_secondImage!);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
          imageProvider,
          maximumColorCount: 35);

      setState(() {
        if (isFirstImage) {
          _palette1 = paletteGenerator;
          _sortPaletteByHue(paletteGenerator.colors.toList());
        } else {
          _palette2 = paletteGenerator;
          _sortPaletteByHue(paletteGenerator.colors.toList());
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

  img.Image recolorImage(
      img.Image source, PaletteGenerator palette1, PaletteGenerator palette2) {
    img.Image newImage = img.Image.from(source);

    final colors1 = palette1.colors.toList();
    final colors2 = palette2.colors.toList();

    double averageHueDifference = _averageHueDifference(colors1, colors2);

    for (int y = 0; y < newImage.height; y++) {
      for (int x = 0; x < newImage.width; x++) {
        final pixelColor = Color(newImage.getPixel(x, y));
        HSLColor pixelColorHSL = HSLColor.fromColor(pixelColor);

        double newHue = (pixelColorHSL.hue - averageHueDifference) % 360;
        HSLColor newPixelColorHSL = pixelColorHSL.withHue(newHue);

        newImage.setPixel(x, y, newPixelColorHSL.toColor().value);
      }
    }

    return newImage;
  }

  double _averageHueDifference(List<Color> colors1, List<Color> colors2) {
    if (colors1.length != colors2.length) {
      if (colors1.length > colors2.length) {
        colors1 = colors1.sublist(0, colors2.length);
      } else {
        colors2 = colors2.sublist(0, colors1.length);
      }
    }

    assert(colors1.length == colors2.length);

    double totalHueDifference = 0;

    for (int i = 0; i < colors1.length; i++) {
      HSLColor color1HSL = HSLColor.fromColor(colors1[i]);
      HSLColor color2HSL = HSLColor.fromColor(colors2[i]);

      double hueDifference = color2HSL.hue - color1HSL.hue;
      totalHueDifference += hueDifference;
    }

    return totalHueDifference / colors1.length;
  }

  img.Image colorTransfer(img.Image source, img.Image target) {
    // Helper function to convert img.Image to List<List<LabColor>>
    List<List<LabColor>> imageToLab(img.Image image) {
      List<List<LabColor>> labMatrix = List.generate(image.height,
          (_) => List.generate(image.width, (_) => const LabColor(0, 0, 0)));

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          int pixelValue = image.getPixel(x, y);
          Color pixelColor = Color(pixelValue);
          labMatrix[y][x] = LabColor.from(
              RgbColor(pixelColor.red, pixelColor.green, pixelColor.blue));
        }
      }
      return labMatrix;
    }

    // Helper function to calculate mean and standard deviation for each channel
    List<num> meanStdDev(List<num> values) {
      num mean = values.reduce((a, b) => a + b) / values.length;
      num variance = values
              .map((value) => (value - mean) * (value - mean))
              .reduce((a, b) => a + b) /
          values.length;
      num stdDev = math.sqrt(variance);
      return [mean, stdDev];
    }

    List<List<LabColor>> sourceLab = imageToLab(source);
    List<List<LabColor>> targetLab = imageToLab(target);

    List<num> sourceL = [];
    List<num> sourceA = [];
    List<num> sourceB = [];
    List<num> targetL = [];
    List<num> targetA = [];
    List<num> targetB = [];

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        sourceL.add(sourceLab[y][x].lightness);
        sourceA.add(sourceLab[y][x].a);
        sourceB.add(sourceLab[y][x].b);
      }
    }

    for (int y = 0; y < target.height; y++) {
      for (int x = 0; x < target.width; x++) {
        targetL.add(targetLab[y][x].lightness);
        targetA.add(targetLab[y][x].a);
        targetB.add(targetLab[y][x].b);
      }
    }

    List<num> sourceLStats = meanStdDev(sourceL);
    List<num> sourceAStats = meanStdDev(sourceA);
    List<num> sourceBStats = meanStdDev(sourceB);
    List<num> targetLStats = meanStdDev(targetL);
    List<num> targetAStats = meanStdDev(targetA);
    List<num> targetBStats = meanStdDev(targetB);

    img.Image result = img.Image(target.width, target.height);
    for (int y = 0; y < target.height; y++) {
      for (int x = 0; x < target.width; x++) {
        LabColor lab = targetLab[y][x];

        num adjustedL = (lab.lightness - targetLStats[0]) *
                (sourceLStats[1] / targetLStats[1]) +
            sourceLStats[0];
        num adjustedA =
            (lab.a - targetAStats[0]) * (sourceAStats[1] / targetAStats[1]) +
                sourceAStats[0];
        num adjustedB =
            (lab.b - targetBStats[0]) * (sourceBStats[1] / targetBStats[1]) +
                sourceBStats[0];

        LabColor adjustedLab = LabColor(
            adjustedL >= 100
                ? 100
                : adjustedL <= 0
                    ? 0
                    : adjustedL,
            adjustedA >= 127
                ? 127
                : adjustedA <= -128
                    ? -128
                    : adjustedA,
            adjustedB >= 127
                ? 127
                : adjustedB <= -128
                    ? -128
                    : adjustedB);
        RgbColor adjustedRgb = adjustedLab.toColor().toRgbColor();

        result.setPixel(
            x,
            y,
            Color.fromRGBO(
                    adjustedRgb.red, adjustedRgb.green, adjustedRgb.blue, 1)
                .value);
      }
    }

    return result;
  }

  double _colorDistance(Color color1, Color color2) {
    final lab1 = LabColor.from(RgbColor(color1.red, color1.green, color1.blue));
    final lab2 = LabColor.from(RgbColor(color2.red, color2.green, color2.blue));
    return lab1.distanceTo(lab2);
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

      // Load and downscale the images
      final image1 = img.decodeImage(await _firstImage!.readAsBytes());
      final image2 = img.decodeImage(await _secondImage!.readAsBytes());

      // Perform the palette-based recoloring
      final transformedImage = colorTransfer(image1!, image2!);

      // Save the modified image locally
      final directory = await getApplicationDocumentsDirectory();
      final generatedImagePath = '${directory.path}/generated_image.png';
      File(generatedImagePath)
          .writeAsBytesSync(img.encodePng(transformedImage));

      // Display the generated image
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

  img.Image downscaleImage(img.Image image, int maxSize) {
    double aspectRatio = image.width / image.height;
    int newWidth;
    int newHeight;

    if (image.width > image.height) {
      newWidth = maxSize;
      newHeight = (newWidth / aspectRatio).round();
    } else {
      newHeight = maxSize;
      newWidth = (newHeight * aspectRatio).round();
    }

    return img.copyResize(image, width: newWidth, height: newHeight);
  }

  Future<void> _saveGeneratedImage() async {
    if (_generatedImageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No generated image to save.')),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final generatedImagePath = '${directory.path}/generated_image.png';
      await GallerySaver.saveImage(generatedImagePath).then(
        (value) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery.')),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image to gallery: $e')),
      );
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _pickImage(true),
                  child: const Center(child: Text('Select Color Source')),
                ),
                if (_firstImage != null) Image.file(_firstImage!),
                if (_palette1 != null) ...[
                  const Text('Color Palette 1:'),
                  Wrap(
                    children: _palette1!.colors.map((color) {
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Container(
                          width: 5,
                          height: 5,
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _pickImage(false),
                  child: const Center(child: Text('Select Destination Image')),
                ),
                if (_secondImage != null) Image.file(_secondImage!),
                if (_palette2 != null) ...[
                  const Text('Color Palette 2:'),
                  Wrap(
                    children: _palette2!.colors.map((color) {
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Container(
                          width: 5,
                          height: 5,
                          color: color,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _generateNewImage(),
                  child: const Center(child: Text('Generate')),
                ),
                if (_generatedImageData != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.memory(_generatedImageData!),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _saveGeneratedImage(),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('Save Generated Image'),
                                Icon(Icons.save)
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 20),
                _resultImageBase64 != null
                    ? Image.memory(base64Decode(_resultImageBase64!))
                    : Text('Result image will be displayed here'),
              ],
            ),
          );
  }
}
