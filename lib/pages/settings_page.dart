import 'package:color_changer/util/shared_preferences_helper.dart';
import 'package:flutter/material.dart';

String? baseUrl;

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController _baseUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  void _loadBaseUrl() async {
    var baseUrl = await SharedPreferencesHelper.getBaseUrl();
    setState(() {
      baseUrl = baseUrl;
      _baseUrlController.text = baseUrl ?? '';
    });
  }

  void _saveBaseUrl() async {
    var baseUrl = _baseUrlController.text.trim();
    await SharedPreferencesHelper.saveBaseUrl(baseUrl);
    setState(() {
      baseUrl = baseUrl;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Base URL:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                hintText: 'Enter Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveBaseUrl,
              child: Text('Save'),
            ),
            SizedBox(height: 16),
            Text(
              'Current Base URL:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(baseUrl ?? 'Not set'),
          ],
        ),
      ),
    );
  }
}
