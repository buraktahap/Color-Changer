import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_editor/flutter_image_editor.dart';
import 'package:image_picker/image_picker.dart';

class WidgetEditableImage extends StatefulWidget {
  const WidgetEditableImage({required this.imageFile, Key? key})
      : super(key: key);

  final File imageFile;

  @override
  WidgetEditableImageState createState() => WidgetEditableImageState();
}

class WidgetEditableImageState extends State<WidgetEditableImage> {
  late StreamController<Uint8List> _pictureStream;
  late double _contrast;
  late double _brightness;
  late Uint8List _picture;

  @override
  void initState() {
    super.initState();
    _pictureStream = StreamController<Uint8List>();
    _contrast = 1;
    _brightness = 0;
    _picture = widget.imageFile.readAsBytesSync();
  }

  void _finishEditing() {
    Navigator.pop(context, widget.imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: <Widget>[
          IconButton(
            onPressed: _finishEditing,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: _containerEditableImage(
        _pictureStream,
        _picture,
        _contrast,
        _brightness,
        _setBrightness,
        _setContrast,
        _updatePicture,
      ),
    );
  }

  void _updatePicture(double contrast, double brightness) async {
    final editedImage =
        await PictureEditor.editImage(_picture, contrast, brightness);
    if (editedImage != null) {
      widget.imageFile.writeAsBytesSync(editedImage);
      _pictureStream.add(editedImage as Uint8List);
    }
    setState(() {
      _brightness = brightness;
      _contrast = contrast;
    });
  }

  void _setBrightness(double value) {
    setState(() {
      _brightness = value;
    });
  }

  void _setContrast(double value) {
    setState(() {
      _contrast = value;
    });
  }
}

Widget _containerEditableImage(
  StreamController<Uint8List> pictureStream,
  Uint8List picture,
  double contrast,
  double brightness,
  void Function(double brightness) setBrightness,
  void Function(double contrast) setContrast,
  void Function(double brightness, double contrast) updatePicture,
) {
  return Container(
    padding: const EdgeInsets.only(top: 50),
    child: Column(
      children: <Widget>[
        Container(
          height: 300,
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: StreamBuilder<Uint8List>(
            stream: pictureStream.stream,
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                return Image.memory(
                  snapshot.data!,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                );
              } else {
                return Image.memory(
                  picture,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                );
              }
            },
          ),
        ),
        Column(
          children: <Widget>[
            const Text('Contrast'),
            Slider(
              label: 'Contrast',
              max: 10,
              value: contrast,
              onChanged: (value) => setContrast(value),
              onChangeEnd: (value) {
                updatePicture(contrast, brightness);
              },
            ),
            const Text('Brightness'),
            Slider(
              label: 'Brightness',
              min: -255,
              max: 255,
              value: brightness,
              onChanged: (value) => setBrightness(value),
              onChangeEnd: (value) {
                updatePicture(contrast, brightness);
              },
            ),
          ],
        ),
      ],
    ),
  );
}

Future<File?> pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.getImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}
