import 'dart:io';
import 'dart:math';

import 'package:color_changer/expansion_tile_v2.dart' as v2;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';

import 'edit_page.dart';

class ImageUploadSection extends StatefulWidget {
  File? image;
  final PaletteGenerator? palette;
  final void Function(File? file) onImageSelected;
  final void Function() onRemoveImage;
  final String title;

  ImageUploadSection({
    Key? key,
    required this.image,
    required this.palette,
    required this.onImageSelected,
    required this.onRemoveImage,
    required this.title,
  }) : super(key: key);

  @override
  State<ImageUploadSection> createState() => ImageUploadSectionState();
}

class ImageUploadSectionState extends State<ImageUploadSection> {
  Uint8List? imageData;
  bool isExpanded = false;
  final v2.ExpansionTileController expansionTileController =
      v2.ExpansionTileController();
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
    return Padding(
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
        title: Text(
            widget.image != null ? widget.title : "Select ${widget.title}"),
        children: [
          widget.image != null
              ? Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.file(widget.image!),
                        ),
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
                              backgroundColor: MaterialStateProperty.all(
                                  Colors.red.shade200),
                              shape: MaterialStateProperty.all(
                                const CircleBorder(),
                              ),
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.all(0),
                              ),
                            ),
                            onPressed: () => widget.onRemoveImage(),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            iconSize: 20,
                            color: Colors.black,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  Colors.blue.shade200),
                              shape: MaterialStateProperty.all(
                                const CircleBorder(),
                              ),
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.all(0),
                              ),
                            ),
                            onPressed: () => setState(() {
                              _editImage();
                            }),
                            icon: const Icon(Icons.edit),
                          ),
                        ),
                      ],
                    ),
                    if (widget.palette != null) ...[
                      // const SizedBox(height: 8),
                      // const Text('Color Palette:'),
                      // _buildPaletteColors(palette!.paletteColors),
                    ],
                  ],
                )
              : Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _pickImage(context),
                      child: const Text('Pick Image'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select an image to get started.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPaletteColors(List<PaletteColor> colors) {
    return Wrap(
      children: colors.map((color) {
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: GestureDetector(
            onTap: () {
              colors.remove(color);
            },
            child: Container(
              width: 10,
              height: 10,
              color: color.color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File? imageFile = File(pickedFile.path);
      if (pickedFile.path.toLowerCase().endsWith('.heic') ||
          pickedFile.path.toLowerCase().endsWith('.heif')) {
        imageFile =
            await _convertToPng(imageFile, pickedFile.path.split('.').last);
      }
      widget.onImageSelected(imageFile);
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
