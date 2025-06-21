import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadImageFirestore extends StatefulWidget {
  const UploadImageFirestore({super.key});

  @override
  _UploadImageFirestoreState createState() => _UploadImageFirestoreState();
}

class _UploadImageFirestoreState extends State<UploadImageFirestore> {
  File? _image;
  final picker = ImagePicker();

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      List<int> imageBytes = await _image!.readAsBytes();
      String base64String = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('farmer_schemes').add({
        'title': 'New Scheme',
        'description': 'Government Support for Farmers',
        'image_base64': base64String,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image Uploaded Successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Image to Firestore")),
      body: Center(
        child: ElevatedButton(
          onPressed: pickImage,
          child: Text("Select & Upload Image"),
        ),
      ),
    );
  }
}
