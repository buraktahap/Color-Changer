import 'dart:convert';
import 'dart:io';
import 'package:color_changer/util/image_repository.dart';
import 'package:color_changer/widgets/image_upload_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

final ImageRepository sourceImageRepository = ImageRepository();
final ImageRepository targetImageRepository = ImageRepository();
PaletteGenerator? editedPalette;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  File? _firstImage;
  File? _secondImage;
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
    return Scaffold(
        appBar: AppBar(
          title: const Text('Color Changer'),
          // actions: [
          //   IconButton(
          //       icon: Icon(Icons.settings),
          //       onPressed: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(builder: (context) => SettingsPage()),
          //         );
          //       }),
          // ],
        ),
        body: _isLoading
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
                      isSourceImage: true,
                      imageRepository: sourceImageRepository,
                      onImageSelected: (file) {
                        setState(() {
                          _firstImage = file;
                          sourceImageRepository.palette = null;
                          sourceImageRepository.paletteCopy = null;
                        });
                      },
                      onRemoveImage: () {
                        setState(() {
                          _firstImage = null;
                          sourceImageRepository.palette = null;
                          sourceImageRepository.paletteCopy = null;
                        });
                      },
                    ),
                    ImageUploadSection(
                      title: "Target Image",
                      image: _secondImage,
                      isSourceImage: false,
                      imageRepository: targetImageRepository,
                      onImageSelected: (file) {
                        setState(() {
                          _secondImage = file;
                          targetImageRepository.palette = null;
                          targetImageRepository.paletteCopy = null;
                        });
                      },
                      onRemoveImage: () {
                        setState(() {
                          _secondImage = null;
                          targetImageRepository.palette = null;
                          targetImageRepository.paletteCopy = null;
                        });
                      },
                    ),
                    _buildGenerateButton(),
                    if (_generatedImageData != null) _buildGeneratedImage(),
                    if (_generatedImageData == null)
                      const Text('Generated Image will be displayed here'),
                  ],
                ),
              ));
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: () {
              setState(() {
                imageKey.currentState?.toggleExpansion();
              });
              _generateNewImage(isPaletteBased: true);
            },
            child: const Center(child: Text('Generate From Palette')),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              setState(() {
                imageKey.currentState?.toggleExpansion();
              });
              _generateNewImage(isPaletteBased: false);
            },
            child: const Center(child: Text('Generate')),
          ),
        ],
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

  Future<void> _generateNewImage({required bool isPaletteBased}) async {
    if (_firstImage == null ||
        _secondImage == null ||
        sourceImageRepository.palette == null ||
        targetImageRepository.palette == null) {
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

      final transformedImage = isPaletteBased
          ? await uploadImageWithPalette(
              _firstImage!,
              _secondImage!,
              sourceImageRepository.palette!,
              sourceImageRepository.paletteCopy!,
            )
          : await uploadImage(
              _firstImage!,
              _secondImage!,
            );

      // final transformedImage = await uploadImage(
      //   _firstImage!,
      //   _secondImage!,
      // );

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

  _shareGeneratedImage() async {
    //share functionality with share_plus package
    final directory = await getApplicationDocumentsDirectory();
    final generatedImagePath = '${directory.path}/generated_image.png';
    Share.shareXFiles(
      [XFile(generatedImagePath)],
    );
  }

  Future uploadImage(File sourceImage, File targetImage) async {
    try {
      _isLoading = true;
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://127.0.0.1:5003/convert'));
      request.files.add(
          await http.MultipartFile.fromPath('source_image', sourceImage.path));
      request.files.add(
          await http.MultipartFile.fromPath('target_image', targetImage.path));

      var response = await request.send();
      var responseStream = response.stream;

      if (response.statusCode == 200) {
        //response body is a Unit8List
        var responseBody =
            await responseStream.toBytes(); // Read the stream once
        //convert the response body to an image
        var generatedImage = img.decodeImage(responseBody);
        return generatedImage;
      } else {
        debugPrint(response.reasonPhrase);
      }
      _isLoading = false;
    } catch (e) {
      debugPrint(e.toString());
      _isLoading = false;
    }
  }

  Future uploadImageWithPalette(File sourceImage, File targetImage,
      PaletteGenerator paletteColors, PaletteGenerator editedColors) async {
    try {
      _isLoading = true;
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://127.0.0.1:5003/convert_with_palette'));
      request.files.add(
          await http.MultipartFile.fromPath('source_image', sourceImage.path));
      request.files.add(
          await http.MultipartFile.fromPath('target_image', targetImage.path));

      // Convert the palettes to the correct format
      var originalPalette = paletteColors.colors
          .map((color) => [color.red, color.green, color.blue])
          .toList();
      var editedPalette = editedColors.colors
          .map((color) => [color.red, color.green, color.blue])
          .toList();

      // Convert the palettes to JSON strings

      var originalPaletteJson = jsonEncode(originalPalette);
      var editedPaletteJson = jsonEncode(editedPalette);
      request.fields['original_palette'] = originalPaletteJson;
      request.fields['edited_palette'] = editedPaletteJson;

      var response = await request.send();
      var responseStream = response.stream;

      if (response.statusCode == 200) {
        //response body is a Unit8List
        var responseBody =
            await responseStream.toBytes(); // Read the stream once
        //convert the response body to an image
        var generatedImage = img.decodeImage(responseBody);
        return generatedImage;
      } else {
        debugPrint(response.reasonPhrase);
      }
      _isLoading = false;
    } catch (e) {
      debugPrint(e.toString());
      _isLoading = false;
    }
  }
}
