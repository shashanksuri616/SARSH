import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';

class FloodPage extends StatefulWidget {
  @override
  _FloodPageState createState() => _FloodPageState();
}

class _FloodPageState extends State<FloodPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _predictedImage;
  String _errorMessage = '';
  String? _selectedSample;
  String? _selectedMask;

  final List<String> _sampleImages = [
    'assets/images/sample1.png', // Replace with the actual paths to your sample images
    'assets/images/sample2.png',
    'assets/images/sample3.png',
  ];



  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _selectedSample = null;
        _selectedMask = null;
        _predictedImage = null;
        _errorMessage = '';
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _image = null;
      _selectedSample = null;
      _selectedMask = null;
      _predictedImage = null;
      _errorMessage = '';
    });
  }


  Future<void> _selectSample(String samplePath) async {
    setState(() {
      _image = null; // Set to null since it's not a File
      _selectedSample = samplePath;
      _selectedMask = 'assets/masks/' + samplePath.split('/').last;
      _predictedImage = null;
      _errorMessage = '';
    });
  }

  // Send the image to the Flask server for prediction
  Future<void> _predict() async {
    if (_image == null && _selectedSample == null) {
      setState(() {
        _errorMessage = 'Please select an image before predicting.';
      });
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.158:5000/flood'), // Replace with your Flask server URL
      );

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _image!.path),
        );
      } else if (_selectedSample != null) {
        ByteData byteData = await rootBundle.load(_selectedSample!);
        List<int> bytes = byteData.buffer.asUint8List();

        request.files.add(
          http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: _selectedSample!.split('/').last
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        setState(() {
          _predictedImage = bytes;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to get prediction. Server returned ${response.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error occurred while connecting to the server.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood Detection'),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Select an Image for Flood Detection',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: _selectedSample,
                  hint: const Text('Select a Sample Image', style: TextStyle(color: Colors.white)),
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: _sampleImages.map((String path) {
                    return DropdownMenuItem<String>(
                      value: path,
                      child: Text(path.split('/').last),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    _selectedSample = value;
                    if (value != null) {
                      await _selectSample(value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                _image == null && _selectedSample == null
                    ? const Text(
                  'No image selected.',
                  style: TextStyle(color: Colors.white),
                )
                    : _image != null
                    ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => PhotoViewPage(image: _image!),
                      ),
                    );
                  },
                  child: Image.file(
                    _image!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                )
                    : Image.asset(
                  _selectedSample!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 20),
                if (_selectedSample == null && _image == null)
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                const SizedBox(height: 20),
                if(_predictedImage == null)
                  ElevatedButton.icon(
                    onPressed: _predict,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Predict'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                if(_predictedImage != null && _selectedSample == null)
                  const Text(
                    'Prediction Result:',
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.white,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                  const SizedBox(height: 20),
                  if(_predictedImage != null && _selectedSample != null)
                    const Text(
                      'Ground Truth:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 20),
                  if(_predictedImage != null && _selectedSample != null)
                    const Text(
                      'Prediction Result:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _predictedImage != null && _selectedSample == null
                    ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            ImageViewPage(imageBytes: _predictedImage!),
                      ),
                    );
                  },
                  child: Image.memory(
                    _predictedImage!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Text(
                  '',
                  style: TextStyle(color: Colors.white),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox(height: 10),
                    _predictedImage != null && _selectedSample != null
                        ? Image.asset(
                          _selectedMask!,
                          height: 150,
                          fit: BoxFit.cover,
                          )
                        : const Text(
                      '',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    _predictedImage != null && _selectedSample != null
                        ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ImageViewPage(imageBytes: _predictedImage!),
                          ),
                        );
                      },
                      child: Image.memory(
                        _predictedImage!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Text(
                      '',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if(_predictedImage != null && _selectedSample != null)
                  const Text(
                    'Model: UNETR           Accuracy: 92%',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.autorenew),
                  alignment: Alignment.topRight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 7.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// PhotoViewPage for viewing selected image
class PhotoViewPage extends StatelessWidget {
  final File image;

  const PhotoViewPage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: PhotoView(
          imageProvider: FileImage(image),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          heroAttributes: const PhotoViewHeroAttributes(tag: "imageHero"),
        ),
      ),
    );
  }
}

// ImageViewPage for viewing prediction result
class ImageViewPage extends StatelessWidget {
  final Uint8List imageBytes;

  const ImageViewPage({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: PhotoView(
          imageProvider: MemoryImage(imageBytes),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          heroAttributes: const PhotoViewHeroAttributes(tag: "resultHero"),
        ),
      ),
    );
  }
}
// // dl_prediction_page.dart
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
//
// class FloodPage extends StatefulWidget {
//   @override
//   _FloodPageState createState() => _FloodPageState();
// }
//
// class _FloodPageState extends State<FloodPage> {
//   File? _image;
//   final ImagePicker _picker = ImagePicker();
//   String _result = '';
//   final List<String> groundTruths = [
//     'Ground Truth 1',
//     'Ground Truth 2',
//     'Ground Truth 3',
//   ];
//
//   // Pick an image from the gallery
//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//     }
//   }
//
//   // Send the image to the Flask server for prediction
//   Future<void> _predict() async {
//     if (_image == null) return;
//
//     final request = http.MultipartRequest(
//       'POST',
//       //   Uri.parse('https://relevant-tick-mna-a0f12a9b.koyeb.app/predict'), // Replace with your Flask server URL
//       // );
//       Uri.parse('http://192.168.1.8:5000/flood'), // Replace with your Flask server URL
//     );
//     request.files.add(
//       await http.MultipartFile.fromPath('image', _image!.path),
//     );
//
//     final response = await request.send();
//     final responseData = await response.stream.bytesToString();
//
//     setState(() {
//       _result = responseData;
//     });
//   }
//
//   // Show a dialog with ground truth values
//   void _showGroundTruths() {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: Text(
//             'Ground Truth Values',
//             style: TextStyle(color: Colors.white),
//           ),
//           content: Container(
//             width: double.maxFinite,
//             child: ListView.builder(
//               itemCount: groundTruths.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(
//                     groundTruths[index],
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 );
//               },
//             ),
//           ),
//           backgroundColor: Colors.black,
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(),
//               child: Text(
//                 'Close',
//                 style: TextStyle(color: Colors.blueAccent),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Flood Detection'),
//         backgroundColor: Colors.white,
//       ),
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'Select an Image',
//                   style: TextStyle(
//                     fontSize: 24,
//                     color: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 _image == null
//                     ? Text(
//                   'No image selected.',
//                   style: TextStyle(color: Colors.white),
//                 )
//                     : GestureDetector(
//                   onTap: () {
//                     // Open a zoomable view of the image
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (BuildContext imageContext) => PhotoViewPage(image: _image!),
//                       ),
//                     );
//                   },
//                   child: Image.file(
//                     _image!,
//                     height: 200,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _pickImage,
//                   style: ButtonStyle(
//                     backgroundColor: MaterialStateProperty.all(Colors.blueAccent),
//                     shape: MaterialStateProperty.all(
//                       RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                     padding: MaterialStateProperty.all(
//                       EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                     ),
//                   ),
//                   child: Text(
//                     'Pick Image',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _predict,
//                   style: ButtonStyle(
//                     backgroundColor: MaterialStateProperty.all(Colors.greenAccent),
//                     shape: MaterialStateProperty.all(
//                       RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                     padding: MaterialStateProperty.all(
//                       EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                     ),
//                   ),
//                   child: Text(
//                     'Predict',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 // ElevatedButton(
//                 //   onPressed: _showGroundTruths,
//                 //   style: ButtonStyle(
//                 //     backgroundColor: MaterialStateProperty.all(Colors.orangeAccent),
//                 //     shape: MaterialStateProperty.all(
//                 //       RoundedRectangleBorder(
//                 //         borderRadius: BorderRadius.circular(30),
//                 //       ),
//                 //     ),
//                 //     padding: MaterialStateProperty.all(
//                 //       EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                 //     ),
//                 //   ),
//                 //   child: Text(
//                 //     'Show Ground Truths',
//                 //     style: TextStyle(
//                 //       color: Colors.white,
//                 //       fontSize: 20,
//                 //     ),
//                 //   ),
//                 // ),
//                 SizedBox(height: 30),
//                 Text(
//                   'Prediction Result:',
//                   style: TextStyle(
//                     fontSize: 20,
//                     color: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   _result.isNotEmpty ? _result : 'No result yet.',
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.white,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // PhotoViewPage class for zooming into the image
// class PhotoViewPage extends StatelessWidget {
//   final File image;
//
//   const PhotoViewPage({required this.image});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: PhotoView(
//           imageProvider: FileImage(image),
//           minScale: PhotoViewComputedScale.contained,
//           maxScale: PhotoViewComputedScale.covered * 2,
//           heroAttributes: const PhotoViewHeroAttributes(tag: "imageHero"),
//         ),
//       ),
//     );
//   }
// }