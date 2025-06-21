import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddProductScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductAdded;
  final Map<String, dynamic>? initialProduct;

  const AddProductScreen(
      {super.key, required this.onProductAdded, this.initialProduct});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedProductType = 'Medicines';
  String? selectedMedicineType = 'Insecticides';

  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  File? _selectedImage;
  String? _imageUrl; // Store the URL for network images
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      // Initialize controllers with product data
      titleController.text = widget.initialProduct!['name'] ?? '';
      priceController.text = widget.initialProduct!['price'] ?? '';
      descriptionController.text = widget.initialProduct!['description'] ?? '';

      // Handle product type selection
      selectedProductType =
          widget.initialProduct!['productType'] ?? 'Medicines';
      selectedMedicineType =
          widget.initialProduct!['medicineType'] ?? 'Insecticides';

      // Handle the image properly
      if (widget.initialProduct!['image'] != null) {
        final imageStr = widget.initialProduct!['image'];
        // Check if it's a network URL
        if (imageStr.toString().startsWith('http')) {
          // Store the URL for network images
          _imageUrl = imageStr;
        } else {
          // Only create File object if it's a file path
          try {
            _selectedImage = File(imageStr);
          } catch (e) {
            // Handle error if not a valid file path
            print('Error creating File object: $e');
          }
        }
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                      _imageUrl =
                          null; // Clear the URL when selecting a new file
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                      _imageUrl =
                          null; // Clear the URL when selecting a new file
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() &&
        titleController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty) {
      try {
        final sellerId = FirebaseAuth.instance.currentUser?.uid;
        if (sellerId == null) {
          throw Exception('Seller not logged in');
        }

        // Create the base product data
        final productData = {
          'name': titleController.text.trim(),
          'price': priceController.text.trim(),
          'description': descriptionController.text.trim(),
          'productType': selectedProductType,
          'medicineType': selectedMedicineType,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Handle the image
        // If we have a new selected image, upload it
        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('product_images')
              .child('$sellerId/${DateTime.now().millisecondsSinceEpoch}.jpg');
          final uploadTask = await storageRef.putFile(_selectedImage!);
          final imageUrl = await uploadTask.ref.getDownloadURL();
          productData['image'] = imageUrl;
        }
        // If we're editing and have an existing image URL but no new image, keep the existing URL
        else if (_imageUrl != null) {
          productData['image'] = _imageUrl;
        }
        // If no image at all, set timestamp for creation
        else if (widget.initialProduct == null) {
          productData['createdAt'] = FieldValue.serverTimestamp();
        }

        // Add or update in Firestore
        if (widget.initialProduct == null ||
            widget.initialProduct!['id'] == null) {
          // Create new product
          await FirebaseFirestore.instance
              .collection('sellers')
              .doc(sellerId)
              .collection('products')
              .add(productData);

          widget.onProductAdded(productData); // Notify parent

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Update existing product
          await FirebaseFirestore.instance
              .collection('sellers')
              .doc(sellerId)
              .collection('products')
              .doc(widget.initialProduct!['id'])
              .update(productData);

          // Add ID to the updated product data
          productData['id'] = widget.initialProduct!['id'];
          widget.onProductAdded(productData); // Notify parent with updated data

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green[700],
        title: Text(
          widget.initialProduct == null ? 'Add Product' : 'Edit Product',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attach Product Image',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade50,
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : _imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error,
                                        color: Colors.red, size: 40),
                                  );
                                },
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image,
                                  size: 60, color: Colors.green),
                            ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Product Type',
                  border: OutlineInputBorder(),
                ),
                value: selectedProductType,
                items: ['Medicines', 'Seeds', 'Fertilizers']
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedProductType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Medicine Type',
                  border: OutlineInputBorder(),
                ),
                value: selectedMedicineType,
                items: ['Insecticides', 'Fungicides', 'Herbicides']
                    .map((type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMedicineType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Required field'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Product Price',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Required field'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Product Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Required field'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _submitForm,
                  child: Text(
                    widget.initialProduct == null
                        ? 'Add Product'
                        : 'Update Product',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
