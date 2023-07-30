import 'package:color_changer/util/shared_preferences_helper.dart';
import 'package:flutter/material.dart';

String? baseUrl;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _baseUrlController = TextEditingController();

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Base URL:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                hintText: 'Enter Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _saveBaseUrl;
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Current Base URL:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(baseUrl ?? 'Not set'),
          ],
        ),
      ),
    );
  }
}
