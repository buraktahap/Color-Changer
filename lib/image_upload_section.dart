import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';

class ImageUploadSection extends StatelessWidget {
  final File? image;
  final PaletteGenerator? palette;
  final void Function(File? file) onImageSelected;
  final void Function() onRemoveImage;
  final String title;

  const ImageUploadSection({
    Key? key,
    required this.image,
    required this.palette,
    required this.onImageSelected,
    required this.onRemoveImage,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ExpansionTile(
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
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.all(8),
        title: Text(image != null ? title : "Select $title"),
        children: [
          image != null
              ? Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.file(image!),
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
                            onPressed: () => onRemoveImage(),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                    if (palette != null) ...[
                      const SizedBox(height: 8),
                      const Text('Color Palette:'),
                      _buildPaletteColors(palette!.paletteColors),
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
      onImageSelected(imageFile);
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
