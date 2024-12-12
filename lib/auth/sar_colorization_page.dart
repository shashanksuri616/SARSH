import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uuid/uuid.dart';

class SARColorizationPage extends StatefulWidget {
  @override
  _SARColorizationPageState createState() => _SARColorizationPageState();
}

class _SARColorizationPageState extends State<SARColorizationPage> {
  File? _inputImage;
  File? _outputImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _selectedSampleImage = '';
  String _selectedGroundTruthImage = '';

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _inputImage = File(pickedFile.path);
        _selectedSampleImage = ''; // Clear sample image selection
        _outputImage = null;
      });
    }
  }

  Future<void> _processImage() async {
    if (_inputImage == null && _selectedSampleImage.isEmpty) return;

    setState(() {
      _isLoading = true;
      _outputImage = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_selectedSampleImage.isNotEmpty
            ? 'http://192.168.1.7:5000/predict_sample' // New route for sample image
            : 'http://192.168.1.7:5000/predict2'),
      );

      if (_selectedSampleImage.isNotEmpty) {
        // Handle asset image
        final byteData = await rootBundle.load(_selectedSampleImage);
        final buffer = byteData.buffer;
        final fileBytes = buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

        // Create MultipartFile from bytes
        final imageMultipart = http.MultipartFile.fromBytes(
          'sample_image',
          fileBytes,
          filename: _selectedSampleImage.split('/').last, // Use the asset filename
        );
        request.files.add(imageMultipart);

        // Send ground truth image along with the request
        final groundTruthByteData = await rootBundle.load(_selectedGroundTruthImage);
        final groundTruthBuffer = groundTruthByteData.buffer;
        final groundTruthBytes = groundTruthBuffer.asUint8List(
          groundTruthByteData.offsetInBytes,
          groundTruthByteData.lengthInBytes,
        );

        final groundTruthMultipart = http.MultipartFile.fromBytes(
          'ground_truth',
          groundTruthBytes,
          filename: _selectedGroundTruthImage.split('/').last,
        );
        request.files.add(groundTruthMultipart);
      } else if (_inputImage != null) {
        // Handle gallery image
        final imageMultipart = await http.MultipartFile.fromPath(
          'image',
          _inputImage!.path,
        );
        request.files.add(imageMultipart);
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final dir = await getTemporaryDirectory();
        final outputFile = File('${dir.path}/${Uuid().v4()}.png');
        await outputFile.writeAsBytes(bytes);

        setState(() {
          _outputImage = outputFile;
        });
      } else {
        _showSnackBar('Failed to process the image.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ButtonStyle _buttonStyle(Color color) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all(color),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildSampleImageDropdown() {
    List<String> sampleImages = [
      'assets/sample_images/sample1.jpg',
      'assets/sample_images/sample2.jpg',
    ];

    return DropdownButton<String>(
      value: _selectedSampleImage.isEmpty ? null : _selectedSampleImage,
      hint: Text('Select Sample Image', style: TextStyle(color: Colors.white)),
      style: TextStyle(color: Colors.white),
      dropdownColor: Colors.grey[800], // Ensures dropdown matches dark theme
      onChanged: (String? newValue) {
        setState(() {
          _selectedSampleImage = newValue!;
          _inputImage = null; // Clear gallery image selection
          _outputImage = null;

          // Set corresponding ground truth image
          _selectedGroundTruthImage =
              newValue.replaceAll('sample_images', 'groundtruth').replaceAll('.jpg', '.png');
        });
      },
      items: sampleImages.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value.split('/').last, style: TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _viewImage(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('View Image'), backgroundColor: Colors.black),
          backgroundColor: Colors.black,
          body: PhotoView(imageProvider: FileImage(image)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SAR Image Colorization'), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('SAR Image Colorization', style: TextStyle(fontSize: 24, color: Colors.white)),
                SizedBox(height: 20),
                _buildSampleImageDropdown(),
                SizedBox(height: 20),
                if (_selectedSampleImage.isNotEmpty)
                  Column(
                    children: [
                      Text('Selected Sample Image', style: TextStyle(color: Colors.white)),
                      Image.asset(_selectedSampleImage,
                          height: 200, width: 200, fit: BoxFit.cover),
                      SizedBox(height: 10),
                      Text('Corresponding Ground Truth Image',
                          style: TextStyle(color: Colors.white)),
                      Image.asset(_selectedGroundTruthImage,
                          height: 200, width: 200, fit: BoxFit.cover),
                    ],
                  ),
                if (_inputImage != null)
                  GestureDetector(
                    onTap: () => _viewImage(_inputImage!),
                    child: Image.file(_inputImage!, height: 200, width: 200, fit: BoxFit.cover),
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: _buttonStyle(Colors.blueAccent),
                  child: Text('Pick Image', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _processImage,
                  style: _buttonStyle(Colors.greenAccent),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Colorize', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                if (_outputImage != null)
                  GestureDetector(
                    onTap: () => _viewImage(_outputImage!),
                    child: Image.file(_outputImage!, height: 200, width: 200, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
