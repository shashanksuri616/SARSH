// import 'dart:io';
// import 'dart:math'; // For random file naming
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:uuid/uuid.dart'; // For UUID to generate random file names
//
// class SARColorizationPage extends StatefulWidget {
//   @override
//   _SARColorizationPageState createState() => _SARColorizationPageState();
// }
//
// class _SARColorizationPageState extends State<SARColorizationPage> {
//   File? _inputImage;
//   File? _outputImage;
//   final ImagePicker _picker = ImagePicker();
//   bool _isLoading = false;
//   bool _showGroundTruth = false;
//   String? _selectedSample;
//   String? _currentGroundTruthPath;
//
//   // List of sample images and ground truth paths
//   final List<Map<String, String>> sampleImages = [
//     {
//       'image': 'D:/Projects/3-1 PS/sars/lib/ROIs1868_summer_s1_59_p10.png',
//       'groundTruth': 'D:/Projects/3-1 PS/sars/lib/ROIs1868_summer_s2_59_p10.png'
//     },
//     {
//       'image': 'D:/Projects/3-1 PS/sars/lib/ROIs1970_fall_s1_114_p1.png',
//       'groundTruth': 'D:/Projects/3-1 PS/sars/lib/ROIs1970_fall_s2_114_p1.png'
//     },
//   ];
//
//   // Pick an image from the gallery
//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _inputImage = File(pickedFile.path);
//         _outputImage = null;
//         _showGroundTruth = false;
//         _selectedSample = null;
//       });
//     }
//   }
//
//   // Load a sample image and its ground truth
//   void _loadSampleImage(String imagePath, String groundTruthPath) {
//     setState(() {
//       print(imagePath);
//       _inputImage = null;
//       _currentGroundTruthPath = groundTruthPath;
//       _selectedSample = imagePath;
//       _showGroundTruth = false;
//     });
//   }
//
//   // Process the selected image
//   Future<void> _processImage() async {
//     if (_inputImage == null && _selectedSample == null) return;
//
//     setState(() {
//       _isLoading = true;
//       _outputImage = null;
//     });
//
//     try {
//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse('http://172.16.20.30:5000/predict2'),
//       );
//
//       final imageFile = await http.MultipartFile.fromPath(
//           'image', _inputImage?.path ?? _selectedSample!);
//       request.files.add(imageFile);
//
//       final response = await request.send();
//
//       if (response.statusCode == 200) {
//         final bytes = await response.stream.toBytes();
//         final dir = await getTemporaryDirectory();
//
//         // Generate random file name for the output image
//         String randomFileName = Uuid().v4() + '.png';
//         final outputFile = File('${dir.path}/$randomFileName');
//         await outputFile.writeAsBytes(bytes);
//
//         setState(() {
//           _outputImage = outputFile;
//         });
//       } else {
//         _showSnackBar('Failed to process the image.');
//       }
//     } catch (e) {
//       _showSnackBar('Error: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   // View the image in a new screen
//   void _viewImage(File image) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => Scaffold(
//           appBar: AppBar(title: Text('View Image'), backgroundColor: Colors.black),
//           backgroundColor: Colors.black,
//           body: PhotoView(
//             imageProvider: FileImage(image),
//             minScale: PhotoViewComputedScale.contained,
//             maxScale: PhotoViewComputedScale.covered * 2,
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Show a snackbar message
//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   }
//
//   // Dropdown for selecting sample images
//   Widget _buildSampleSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Select a Sample Image',
//             style: TextStyle(fontSize: 18, color: Colors.white)),
//         SizedBox(height: 10),
//         DropdownButton<String>(
//           value: _selectedSample,
//           hint: Text('Choose a sample',
//               style: TextStyle(color: Colors.white, fontSize: 16)),
//           dropdownColor: Colors.grey[900],
//           isExpanded: true,
//           items: sampleImages.map((sample) {
//             return DropdownMenuItem<String>(
//               value: sample['image'],
//               child: Text(sample['image']!, style: TextStyle(color: Colors.white)),
//             );
//           }).toList(),
//           onChanged: (value) {
//             final selectedSample = sampleImages
//                 .firstWhere((sample) => sample['image'] == value);
//             _loadSampleImage(selectedSample['image']!, selectedSample['groundTruth']!);
//             setState(() {
//               _selectedSample = value;
//             });
//           },
//         ),
//       ],
//     );
//   }
//
//   // Ground Truth display toggle
//   Widget _buildGroundTruthToggle() {
//     if (_selectedSample == null) return SizedBox.shrink();
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Show Ground Truth:', style: TextStyle(color: Colors.white)),
//             Switch(
//               value: _showGroundTruth,
//               onChanged: (value) => setState(() {
//                 _showGroundTruth = value;
//               }),
//             ),
//           ],
//         ),
//         if (_showGroundTruth && _currentGroundTruthPath != null)
//           Column(
//             children: [
//               Text('Ground Truth Image', style: TextStyle(color: Colors.white)),
//               SizedBox(height: 10),
//               Image.asset(
//                 _currentGroundTruthPath!,
//                 height: 200,
//                 width: 200,
//                 fit: BoxFit.cover,
//               ),
//             ],
//           ),
//       ],
//     );
//   }
//
//   // Button Style and Text helpers
//   ButtonStyle _buttonStyle(Color color) {
//     return ButtonStyle(
//       backgroundColor: MaterialStateProperty.all(color),
//       shape: MaterialStateProperty.all(
//         RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//       ),
//       padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
//     );
//   }
//
//   Widget _buttonText(String text) {
//     return Text(
//       text,
//       style: TextStyle(color: Colors.white, fontSize: 20),
//     );
//   }
//
//   // Additional Method for Handling File Picker & Error Scenarios
//   Future<void> _handleFilePickError(dynamic error) async {
//     _showSnackBar("Error: Unable to pick file. Please try again.");
//   }
//
//   // Method to simulate network delay
//   Future<void> _simulateNetworkDelay() async {
//     await Future.delayed(Duration(seconds: 3));
//   }
//
//   // Advanced Input Validation for Image File
//   bool _validateInputImage(File? image) {
//     return image != null && image.existsSync();
//   }
//
//   // Main Build Method
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('SAR Image Colorization'), backgroundColor: Colors.black),
//       backgroundColor: Colors.black,
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text('SAR Image Colorization', style: TextStyle(fontSize: 24, color: Colors.white)),
//               const SizedBox(height: 20),
//               _buildSampleSelector(),
//               SizedBox(height: 20),
//               if (_inputImage != null) ...[
//                 Text('Input Image', style: TextStyle(color: Colors.white)),
//                 GestureDetector(
//                   onTap: () => _viewImage(_inputImage!),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.file(
//                       _inputImage!,
//                       height: 200,
//                       width: 200,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//               ],
//               _buildGroundTruthToggle(),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _pickImage,
//                 style: _buttonStyle(Colors.blueAccent),
//                 child: _buttonText('Pick Image'),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _processImage,
//                 style: _buttonStyle(Colors.greenAccent),
//                 child: _isLoading
//                     ? CircularProgressIndicator(color: Colors.white)
//                     : _buttonText('Colorize'),
//               ),
//               if (_outputImage != null) ...[
//                 SizedBox(height: 20),
//                 Text('Output Image', style: TextStyle(color: Colors.white)),
//                 GestureDetector(
//                   onTap: () => _viewImage(_outputImage!),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.file(
//                       _outputImage!,
//                       height: 200,
//                       width: 200,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uuid/uuid.dart'; // For UUID to generate random file names

class SARColorizationPage extends StatefulWidget {
  @override
  _SARColorizationPageState createState() => _SARColorizationPageState();
}

class _SARColorizationPageState extends State<SARColorizationPage> {
  File? _inputImage;
  File? _outputImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _inputImage = File(pickedFile.path);
        _outputImage = null;
      });
    }
  }

  // Process the selected image
  Future<void> _processImage() async {
    if (_inputImage == null) return;

    setState(() {
      _isLoading = true;
      _outputImage = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://172.16.20.30:5000/predict2'),
      );

      final imageFile = await http.MultipartFile.fromPath('image', _inputImage!.path);
      request.files.add(imageFile);

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final dir = await getTemporaryDirectory();

        String randomFileName = Uuid().v4() + '.png';
        final outputFile = File('${dir.path}/$randomFileName');
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

  // View the image in a new screen
  void _viewImage(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('View Image'), backgroundColor: Colors.black),
          backgroundColor: Colors.black,
          body: PhotoView(
            imageProvider: FileImage(image),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  // Show a snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Button Style and Text helpers
  ButtonStyle _buttonStyle(Color color) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all(color),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
    );
  }

  Widget _buttonText(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.white, fontSize: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SAR Image Colorization'), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text('SAR Image Colorization', style: TextStyle(fontSize: 24, color: Colors.white)),
              const SizedBox(height: 20),
              if (_inputImage != null) ...[
                Text('Input Image', style: TextStyle(color: Colors.white)),
                GestureDetector(
                  onTap: () => _viewImage(_inputImage!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _inputImage!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
              ElevatedButton(
                onPressed: _pickImage,
                style: _buttonStyle(Colors.blueAccent),
                child: _buttonText('Pick Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _processImage,
                style: _buttonStyle(Colors.greenAccent),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : _buttonText('Colorize'),
              ),
              if (_outputImage != null) ...[
                SizedBox(height: 20),
                Text('Output Image', style: TextStyle(color: Colors.white)),
                GestureDetector(
                  onTap: () => _viewImage(_outputImage!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _outputImage!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
