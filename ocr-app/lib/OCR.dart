import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ImageUploadPage extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _image;
  final picker = ImagePicker();
  String _resultText = '';
  bool _isLoading = false; //
  String type = "";

  @override
  void dispose() {
    super.dispose();
  }

  Future<String?> _getSavedIP() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(
        'saved_ip'); // This will return null if 'saved_ip' is not set
  }

  Future getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadImage() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    // Retrieve the saved IP address
    String? savedIP = await _getSavedIP();
    // Use a default IP if none is saved
    String url = 'http://${savedIP ?? "192.168.137.39"}:5000/process_image';

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    var res = await request.send();
    var responseData = await res.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);

    setState(() {
      var responseJson = jsonDecode(responseString);
      _resultText = responseJson.values.join(' ');
      _isLoading = false; // End loading
    });
  }

  void showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Photo Library'),
                    onTap: () {
                      getImage(ImageSource.gallery);
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Camera'),
                    onTap: () {
                      getImage(ImageSource.camera);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white), // Add this line
        backgroundColor: Color.fromRGBO(31, 44, 52, 1),
        title: Text(
          'OCR / Handwirten Text Recognition',
          style: TextStyle(color: Colors.white54),
        ),
      ),
      body: Container(
        color: Color.fromRGBO(31, 44, 52, 1),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                    ),
                    _image == null
                        ? GestureDetector(
                            onTap: () => showImageSourceActionSheet(context),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.image,
                                  size: MediaQuery.of(context).size.width - 100,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () => showImageSourceActionSheet(context),
                            child: Image.file(
                              _image!,
                              width: MediaQuery.of(context).size.width - 100,
                            ),
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    _isLoading
                        ? CircularProgressIndicator() // Show loading indicator when loading
                        : ElevatedButton.icon(
                            icon: Icon(Icons.scanner,
                                color: Colors.white), // Use the scanner icon
                            label: Text(
                              'Scan Image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                Colors.tealAccent.withOpacity(0.08),
                              ),
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10)),
                              shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                            ),
                            onPressed: _isLoading
                                ? null
                                : uploadImage, // Disable the button when loading
                          )
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 8,
                ), // Set your desired padding here
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SingleChildScrollView(
                          child: TextField(
                            controller:
                                TextEditingController(text: _resultText),
                            maxLines: null, // makes the TextField multi-line
                            readOnly: true, // makes the TextField read-only
                            decoration: InputDecoration(
                              hintStyle: TextStyle(fontSize: 17),
                              hintText: 'Scanned Text will appear here...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(20),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _resultText));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
