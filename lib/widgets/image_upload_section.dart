// ignore_for_file: must_be_immutable

import 'dart:io';
import 'dart:math';

import 'package:color_changer/widgets/expansion_tile_v2.dart' as v2;
import 'package:color_changer/pages/home_page.dart';
import 'package:color_changer/util/image_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../pages/edit_page.dart';

class ImageUploadSection extends StatefulWidget {
  File? image;
  final bool isSourceImage;
  final void Function(File? file) onImageSelected;
  final void Function() onRemoveImage;
  final String title;
  final ImageRepository imageRepository;

  ImageUploadSection({
    Key? key,
    required this.image,
    required this.onImageSelected,
    required this.onRemoveImage,
    required this.title,
    required this.imageRepository,
    required this.isSourceImage,
  }) : super(key: key);

  @override
  State<ImageUploadSection> createState() => ImageUploadSectionState();
}

class ImageUploadSectionState extends State<ImageUploadSection> {
  Uint8List? imageData;
  bool isExpanded = false;
  final v2.ExpansionTileController expansionTileController =
      v2.ExpansionTileController();
  VideoPlayerController? controller;

  void toggleExpansion() {
    setState(() {
      expansionTileController.expand();
    });
  }

  void toogleCollapse() {
    setState(() {
      expansionTileController.collapse();
    });
  }

  @override
  void initState() {
    super.initState();
    loadImage();
    // Initialize the controller only for video files
    if (widget.image != null) {
      if (widget.image!.path.toLowerCase().contains('.mov') ||
          widget.image!.path.toLowerCase().contains('.mp4')) {
        controller = VideoPlayerController.file(widget.image!);
        controller!.addListener(() {
          setState(() {});
        });
        controller!.setLooping(true);
        controller!.initialize().then((_) => setState(() {}));
        controller!.play();
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void loadImage() async {
    var bytes = await widget.image?.readAsBytes();
    setState(() {
      imageData = bytes;
    });
  }

  void _editImage() async {
    final editedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WidgetEditableImage(imageFile: widget.image!),
      ),
    );

    if (editedImage != null && editedImage is Uint8List) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = "${directory.path}/${DateTime.now()}.jpg";
      final imageFile = File(imagePath);

      await imageFile.writeAsBytes(editedImage);

      setState(() {
        widget.image = imageFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return mounted
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: v2.ExpansionTileV2(
              controller: expansionTileController,
              onExpansionChanged: (value) {
                setState(() {
                  isExpanded = value;
                });
              },
              trailing: Transform.rotate(
                angle: isExpanded ? pi : 0,
                child: const Icon(Icons.keyboard_arrow_down_sharp),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              childrenPadding: const EdgeInsets.all(8),
              backgroundColor: Colors.grey.shade200,
              collapsedBackgroundColor: Colors.grey.shade200,
              maintainState: true,
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              clipBehavior: Clip.antiAlias,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.all(8),
              title: Text(widget.image != null
                  ? widget.title
                  : "Select ${widget.title}"),
              children: [
                widget.image != null
                    ? Column(
                        children: [
                          Stack(
                            children: [
                              //file can be a video too. so we need to check if it is a video or not
                              if (widget.image!.path
                                      .toLowerCase()
                                      .contains('.mov') ||
                                  widget.image!.path
                                      .toLowerCase()
                                      .contains('.mp4'))
                                controller != null &&
                                        controller!.value.isInitialized
                                    ? AspectRatio(
                                        aspectRatio:
                                            controller!.value.aspectRatio,
                                        child: VideoPlayer(controller!),
                                      )
                                    : Container()
                              else
                                Image.file(widget.image!),

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
                                    backgroundColor: WidgetStateProperty.all(
                                        Colors.red.shade200),
                                    shape: WidgetStateProperty.all(
                                      const CircleBorder(),
                                    ),
                                    padding: WidgetStateProperty.all(
                                      const EdgeInsets.all(0),
                                    ),
                                  ),
                                  onPressed: () => widget.onRemoveImage(),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                              // Positioned(
                              //   bottom: 0,
                              //   right: 0,
                              //   child: IconButton(
                              //     iconSize: 20,
                              //     color: Colors.black,
                              //     constraints: const BoxConstraints(
                              //       minWidth: 30,
                              //       minHeight: 30,
                              //     ),
                              //     style: ButtonStyle(
                              //       backgroundColor: MaterialStateProperty.all(
                              //           Colors.blue.shade200),
                              //       shape: MaterialStateProperty.all(
                              //         const CircleBorder(),
                              //       ),
                              //       padding: MaterialStateProperty.all(
                              //         const EdgeInsets.all(0),
                              //       ),
                              //     ),
                              //     onPressed: () => setState(() {
                              //       _editImage();
                              //     }),
                              //     icon: const Icon(Icons.edit),
                              //   ),
                              // ),
                            ],
                          ),
                          if (widget.imageRepository.palette != null) ...[
                            const SizedBox(height: 8),
                            const Text('Color Palette:'),
                            if (widget.isSourceImage) _buildPaletteColors(),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _pickImageFromGallery(context),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Pick Image'),
                                      SizedBox(width: 8),
                                      Icon(Icons.photo),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _pickImageFromCamera(context),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Take Photo'),
                                      SizedBox(width: 8),
                                      Icon(Icons.camera_alt),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          //video
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _pickVideoFromGallery(context),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Pick Video'),
                                      SizedBox(width: 8),
                                      Icon(Icons.video_collection),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _pickVideoFromCamera(context),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Take Video'),
                                      SizedBox(width: 8),
                                      Icon(Icons.video_call),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Select an image to get started.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ],
            ),
          )
        : Container();
  }

  Widget _buildPaletteColors() {
    // Copy list
    return Wrap(
      children: widget.imageRepository.paletteCopy!.paletteColors.map((color) {
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                widget.imageRepository.paletteCopy!.paletteColors.remove(color);
              });
            },
            child: Container(
              width: 25,
              height: 25,
              color: color.color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File? imageFile = File(pickedFile.path);
      if (pickedFile.path.toLowerCase().endsWith('.heic') ||
          pickedFile.path.toLowerCase().endsWith('.heif')) {
        imageFile =
            await _convertToPng(imageFile, pickedFile.path.split('.').last);
      }
      setState(() {
        widget.onImageSelected(imageFile);
        _generatePalette(imageFile!);
      });
    }
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      File? imageFile = File(pickedFile.path);
      if (pickedFile.path.toLowerCase().endsWith('.heic') ||
          pickedFile.path.toLowerCase().endsWith('.heif')) {
        imageFile =
            await _convertToPng(imageFile, pickedFile.path.split('.').last);
      }
      setState(() {
        widget.onImageSelected(imageFile);
        _generatePalette(imageFile!);
      });
      editedPalette = widget.imageRepository.palette;
    }
  }

  Future<void> _pickVideoFromGallery(BuildContext context) async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      File? videoFile = File(pickedFile.path);
      setState(() {
        widget.onImageSelected(videoFile);
      });
    }
  }

  Future<void> _pickVideoFromCamera(BuildContext context) async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      File? videoFile = File(pickedFile.path);
      setState(() {
        widget.onImageSelected(videoFile);
      });
    }
  }

  Future<void> _generatePalette(File image) async {
    try {
      final imageProvider = FileImage(image);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 30,
      );
      PaletteGenerator paletteGeneratorCopy = PaletteGenerator.fromColors(
        [...paletteGenerator.paletteColors],
      );
      setState(() {
        widget.imageRepository.palette = paletteGenerator;
        widget.imageRepository.paletteCopy = paletteGeneratorCopy;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating palette: $e')),
      );
    }
  }

  Future<File> _convertToPng(File inputFile, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final pngFilePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    final pngFile = File(pngFilePath);
    final compressedData = await FlutterImageCompress.compressWithFile(
      inputFile.absolute.path,
      minWidth: 800,
      minHeight: 600,
      quality: 90,
      rotate: 0,
      format: CompressFormat.png,
    );
    await pngFile.writeAsBytes(compressedData!);
    return pngFile;
  }
}
