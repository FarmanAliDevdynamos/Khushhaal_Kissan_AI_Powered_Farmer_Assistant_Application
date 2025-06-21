import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khushhal_kisan_app/pages/seller/sellerdashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Sellerhomescreen extends StatefulWidget {
  final String? initialName;
  final String? initialStoreName;
  final String? initialStoreAddress;
  final String? initialCity;
  final String? initialPhone;
  final String? initialProvince;
  final String? initialStoreLogo;

  const Sellerhomescreen({
    super.key,
    this.initialName,
    this.initialStoreName,
    this.initialStoreAddress,
    this.initialCity,
    this.initialPhone,
    this.initialProvince,
    this.initialStoreLogo,
  });

  @override
  _SellerhomescreenState createState() => _SellerhomescreenState();
}

class _SellerhomescreenState extends State<Sellerhomescreen> {
  late final TextEditingController nameController;
  late final TextEditingController storeNameController;
  late final TextEditingController storeAddressController;
  late final TextEditingController cityController;
  late final TextEditingController phoneController;
  late String selectedProvince;
  File? _image;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with initial values
    nameController = TextEditingController(text: widget.initialName ?? '');
    storeNameController =
        TextEditingController(text: widget.initialStoreName ?? '');
    storeAddressController =
        TextEditingController(text: widget.initialStoreAddress ?? '');
    cityController = TextEditingController(text: widget.initialCity ?? '');
    phoneController = TextEditingController(text: widget.initialPhone ?? '');
    selectedProvince =
        widget.initialProvince ?? 'Punjab'; // Default to 'Punjab'

    // Handle initialStoreLogo properly - keep URL as URL, convert file path to File
    if (widget.initialStoreLogo != null) {
      if (widget.initialStoreLogo!.startsWith('http')) {
        // Store URL for later use
        _existingImageUrl = widget.initialStoreLogo;
      } else {
        // Try to create File from local path
        try {
          _image = File(widget.initialStoreLogo!);
        } catch (e) {
          print("Error creating file from path: ${widget.initialStoreLogo}");
        }
      }
    }

    // Only check store info for new stores, not when editing
    if (widget.initialStoreName == null || widget.initialStoreName!.isEmpty) {
      _checkStoreInfo();
    }
  }

  Future<void> _checkStoreInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        String? storeLogo = data['storeLogo'] ?? '';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SellerManageStore(
              storeName: data['storeName'] ?? '',
              storeAddress: data['storeAddress'] ?? '',
              phone: data['phone'] ?? '',
              storeLogo: storeLogo,
              products: [],
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    nameController.dispose();
    storeNameController.dispose();
    storeAddressController.dispose();
    cityController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        // Clear existing URL since we have a new file
        _existingImageUrl = null;
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text(
          'Seller Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                // CircleAvatar(
                //   radius: 55,
                //   backgroundColor: Colors.green.shade100,
                //   backgroundImage: _image != null
                //       ? FileImage(_image!)
                //       : (_existingImageUrl != null
                //           ? NetworkImage(_existingImageUrl!) as ImageProvider
                //           : null),
                //   onBackgroundImageError: (exception, stackTrace) {
                //     // Handle image loading errors
                //     print('Error loading profile image: $exception');
                //   },
                //   child: (_image == null && _existingImageUrl == null)
                //       ? const Icon(Icons.person, size: 55, color: Colors.white)
                //       : null,
                // ),

                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (_existingImageUrl != null
                          ? NetworkImage(_existingImageUrl!) as ImageProvider
                          : null),
                  // Only set error handler when there's a background image
                  onBackgroundImageError:
                      (_image != null || _existingImageUrl != null)
                          ? (exception, stackTrace) {
                              print('Error loading profile image: $exception');
                            }
                          : null,
                  child: (_image == null && _existingImageUrl == null)
                      ? const Icon(Icons.person, size: 55, color: Colors.white)
                      : null,
                ),

                Positioned(
                  child: GestureDetector(
                    onTap: _showImagePicker,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit,
                          color: Colors.green.shade700, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInputField('Your Name', nameController),
            _buildInputField('Store Name', storeNameController),
            _buildInputField('Store Address', storeAddressController),
            _buildInputField('City', cityController),
            _buildInputField('Phone', phoneController,
                keyboardType: TextInputType.phone),
            _buildDropdownField(
                'Province', ['Punjab', 'Sindh', 'Balochistan', 'KPK']),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                print('Save button clicked');
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  print('User is not authenticated');
                  return;
                }

                print('User authenticated: ${user.uid}');

                // For editing, don't force image selection if there's already an existing URL
                if (_image == null && _existingImageUrl == null) {
                  print('No image selected');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an image')),
                  );
                  return;
                }

                String? imageUrl =
                    _existingImageUrl; // Keep existing URL if there's no new image
                if (_image != null) {
                  try {
                    print('Uploading image...');
                    final storageRef = FirebaseStorage.instance.ref().child(
                        'seller_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    final uploadTask = storageRef.putFile(_image!);

                    // Monitor the upload progress
                    uploadTask.snapshotEvents.listen((event) {
                      print(
                          'Progress: ${(event.bytesTransferred / event.totalBytes) * 100}%');
                    });

                    await uploadTask; // Wait for the upload to complete
                    print('Upload completed');
                    imageUrl = await storageRef.getDownloadURL();
                    print('Image uploaded: $imageUrl');
                  } catch (e) {
                    print('Failed to upload image: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to upload image: $e')),
                    );
                    return;
                  }
                }

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('sellers')
                        .doc(user.uid)
                        .set({
                      'storeName': storeNameController.text,
                      'storeAddress': storeAddressController.text,
                      'phone': phoneController.text,
                      'storeLogo': imageUrl ?? '',
                    });

                    // Navigate to SellerManageStore after saving
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerManageStore(
                          storeName: storeNameController.text,
                          storeAddress: storeAddressController.text,
                          phone: phoneController.text,
                          storeLogo: imageUrl,
                          products: [],
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  print('Failed to save store information: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to save store information: $e')),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save & Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green.shade700),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedProvince,
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green.shade700),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
          ),
        ),
        items: items.map((province) {
          return DropdownMenuItem<String>(
            value: province,
            child: Text(province),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            selectedProvince = newValue!;
          });
        },
      ),
    );
  }
}
