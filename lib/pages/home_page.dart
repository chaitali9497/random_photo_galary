import 'dart:io';
import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:random_photo_galary/constants.dart';
import 'package:random_photo_galary/pages/Search_Page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String imageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImage();
  }

  Future<void> fetchImage() async {
    final response = await http.get(Uri.parse(
        api));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      setState(() {
        imageUrl = jsonResponse['urls']['regular'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load image');
    }
  }

  void _startDownload() async {
    final taskId = await FlutterDownloader.enqueue(
      url: imageUrl,
      savedDir: (await getExternalStorageDirectory())!.path,
      showNotification: true,
      openFileFromNotification: true,
    );
    print('Download task id: $taskId');
  }

  Future<void> _saveImage(BuildContext context) async {
    String? message;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Download image
      final http.Response response = await http.get(Uri.parse(imageUrl));

      // Get temporary directory
      final dir = await getTemporaryDirectory();

      // Create an image name
      var filename =
          '${dir.path}/image_${DateTime.now().toIso8601String()}.png';

      // Save to filesystem
      final file = File(filename);
      await file.writeAsBytes(response.bodyBytes);

      // Ask the user to save it
      final params = SaveFileDialogParams(sourceFilePath: file.path);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'Image saved to disk';
      }
    } catch (e) {
      message = 'An error occurred while saving the image';
    }

    if (message != null) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _setWallpaper() async {
    bool result = await AsyncWallpaper.setWallpaper(url: imageUrl);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (result) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Wallpaper set successfully!')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to set wallpaper.')),
      );
    }
  }

  Future<void> _RefreshImage() async {
    final response = await http.get(Uri.parse(
        api));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      setState(() {
        imageUrl = jsonResponse['urls']['regular'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        title: const Center(
          child: Text(
            "Wally",
            style: TextStyle(
              color: Colors.black,
              fontSize: 45,
              fontStyle: FontStyle.normal,
            ),
          ),
        ),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Image.network(
                imageUrl,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.fill,
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _RefreshImage(),
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _saveImage(context),
            tooltip: 'Save Image',
            child: const Icon(Icons.download),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _setWallpaper,
            tooltip: 'Set Wallpaper',
            child: const Icon(Icons.wallpaper),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
            child: Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
