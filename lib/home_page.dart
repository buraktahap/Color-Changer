import 'dart:io';
import 'dart:math' as math;
import 'package:color_changer/image_upload_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  Uint8List? _generatedImageData;
  bool _isLoading = false;
  GlobalKey<ImageUploadSectionState> imageKey = GlobalKey();

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
    return _isLoading
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ImageUploadSection(
                  title: "Color Source Image",
                  image: _firstImage,
                  palette: _palette1,
                  onImageSelected: (file) {
                    setState(() {
                      _firstImage = file;
                      _palette1 = null;
                    });
                    _generatePalette(true);
                  },
                  onRemoveImage: () {
                    setState(() {
                      _firstImage = null;
                      _palette1 = null;
                    });
                  },
                ),
                ImageUploadSection(
                  title: "Target Image",
                  image: _secondImage,
                  palette: _palette2,
                  onImageSelected: (file) {
                    setState(() {
                      _secondImage = file;
                      _palette2 = null;
                    });
                    _generatePalette(false);
                  },
                  onRemoveImage: () {
                    setState(() {
                      _secondImage = null;
                      _palette2 = null;
                    });
                  },
                ),
                _buildGenerateButton(),
                if (_generatedImageData != null) _buildGeneratedImage(),
                if (_generatedImageData == null)
                  const Text('Generated Image will be displayed here'),
              ],
            ),
          );
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FilledButton(
        onPressed: () {
          setState(() {
            imageKey.currentState?.toggleExpansion();
          });
          _generateNewImage();
        },
        child: const Center(child: Text('Generate')),
      ),
    );
  }

  Widget _buildGeneratedImage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(children: [
              Image.memory(_generatedImageData!),
              Positioned(
                right: 0,
                child: IconButton(
                  iconSize: 20,
                  color: Colors.black,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.red.shade200),
                    shape: MaterialStateProperty.all(
                      const CircleBorder(),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.all(0),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _generatedImageData = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _saveGeneratedImage(),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Save Generated Image'),
                        Icon(Icons.save),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              //share button
              FilledButton(
                onPressed: () => _shareGeneratedImage(),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Share'),
                      Icon(Icons.share),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
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
        maximumColorCount: 10,
      );

      setState(() {
        if (isFirstImage) {
          _palette1 = paletteGenerator;
        } else {
          _palette2 = paletteGenerator;
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

  Future<void> _generateNewImage() async {
    if (_firstImage == null ||
        _secondImage == null ||
        _palette1 == null ||
        _palette2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both images and generate palettes.'),
        ),
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
      final downscaledImage1 = downscaleImage(image1!, 800);
      final downscaledImage2 = downscaleImage(image2!, 800);

      // Perform the palette-based recoloring
      final transformedImage =
          colorTransfer(downscaledImage1, downscaledImage2);

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

  img.Image colorTransfer(img.Image source, img.Image target) {
    // Helper function to convert img.Image to List<List<LabColor>>
    Map<int, LabColor> labColorCache = {};

    List<List<LabColor>> imageToLab(img.Image image) {
      List<List<LabColor>> labMatrix = List.generate(
        image.height,
        (_) => List.generate(
          image.width,
          (_) => const LabColor(0, 0, 0),
        ),
      );

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          int pixelValue = image.getPixel(x, y);
          if (!labColorCache.containsKey(pixelValue)) {
            Color pixelColor = Color(pixelValue);
            labColorCache[pixelValue] = LabColor.from(
              RgbColor(pixelColor.red, pixelColor.green, pixelColor.blue),
            );
          }
          labMatrix[y][x] = labColorCache[pixelValue]!;
        }
      }
      return labMatrix;
    }

    // Helper function to calculate mean and standard deviation for each channel
    List<num> meanStdDev(List<num> values) {
      num mean = 0;
      num m2 = 0;
      for (int i = 0; i < values.length; i++) {
        num delta = values[i] - mean;
        mean += delta / (i + 1);
        m2 += delta * (values[i] - mean);
      }
      num variance = m2 / (values.length - 1);
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
                  : adjustedB,
        );
        RgbColor adjustedRgb = adjustedLab.toColor().toRgbColor();

        result.setPixel(
          x,
          y,
          Color.fromRGBO(
            adjustedRgb.red,
            adjustedRgb.green,
            adjustedRgb.blue,
            1,
          ).value,
        );
      }
    }

    return result;
  }

  _shareGeneratedImage() async {
    //share functionality with share_plus package
    final directory = await getApplicationDocumentsDirectory();
    final generatedImagePath = '${directory.path}/generated_image.png';
    Share.shareFiles(
      [generatedImagePath],
    );
  }
}
