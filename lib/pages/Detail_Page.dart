import 'dart:convert';
import 'dart:io';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:random_photo_galary/constants.dart';
import 'package:random_photo_galary/pages/Search_Page.dart';

class DetailPage extends StatefulWidget {
  final SearchResult result;

  const DetailPage({Key? key, required this.result}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late String imageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize imageUrl from widget's initial result
    imageUrl = widget.result.imageUrl;
  }

  

  Future<void> _saveImage(BuildContext context) async {
    String? message;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));

      final dir = await getTemporaryDirectory();
      var filename = '${dir.path}/image_${DateTime.now().toIso8601String()}.png';

      final file = File(filename);
      await file.writeAsBytes(response.bodyBytes);

      final params = SaveFileDialogParams(sourceFilePath: file.path);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'Image saved to disk';
      }
    } catch (e) {
      message = 'An error occurred while saving the image';
      print('Error saving image: $e');
    }

    if (message != null) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _setWallpaper() async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
     bool result = await AsyncWallpaper.setWallpaper(url: imageUrl);

    if (result) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Wallpaper set successfully!')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to set wallpaper.')),
      );
    }
  } catch (e) {
    print('Error setting wallpaper: $e');
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Failed to set wallpaper. Please try again later.')),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
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
          FloatingActionButton(
            onPressed: () {
            Navigator.of(context).pop();
          },
          child: Icon(Icons.arrow_back_rounded),
        ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _saveImage(context),
            tooltip: 'Save Image',
            child: Icon(Icons.download),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _setWallpaper,
            tooltip: 'Set Wallpaper',
            child: Icon(Icons.wallpaper),
          ),
          SizedBox(height: 10),
          
        ],
      ),
    );
  }
}
