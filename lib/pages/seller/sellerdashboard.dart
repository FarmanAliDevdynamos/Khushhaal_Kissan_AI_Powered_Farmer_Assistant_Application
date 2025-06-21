
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';
import 'package:khushhal_kisan_app/pages/seller/addproductscreen.dart';
import 'package:khushhal_kisan_app/pages/seller/sellerhomescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SellerManageStore extends StatefulWidget {
  final String storeName;
  final String storeAddress;
  final String phone;
  final String? storeLogo;
  final List<Map<String, dynamic>> products;

  const SellerManageStore({
    super.key,
    required this.storeName,
    required this.storeAddress,
    required this.phone,
    this.storeLogo,
    required this.products,
  });

  @override
  _SellerManageStoreState createState() => _SellerManageStoreState();
}

class _SellerManageStoreState extends State<SellerManageStore> {
  late Stream<QuerySnapshot> productsStream;
  late StreamSubscription<QuerySnapshot> _productsSubscription;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();

    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    if (sellerId != null) {
      productsStream = FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('products')
          .snapshots();

      _productsSubscription = productsStream.listen((snapshot) {
        setState(() {
          _products = snapshot.docs
              .map((doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  })
              .toList();
        });
      });
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          onProductAdded: (updatedProduct) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          initialProduct: product,
        ),
      ),
    );
  }

  void _deleteProduct(Map<String, dynamic> product) {
    if (product['id'] != null) {
      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId != null) {
        // Show confirmation dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Product'),
            content:
                const Text('Are you sure you want to delete this product?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  _performProductDeletion(sellerId, product);
                },
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _performProductDeletion(
      String sellerId, Map<String, dynamic> product) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deleting product...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Reference to the document to delete
      final productRef = FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('products')
          .doc(product['id']);

      // Delete the document from Firestore
      await productRef.delete();

      // After successful Firestore deletion, delete the image from Storage if it exists
      if (product['image'] != null) {
        try {
          await _deleteProductImage(product['image']);
          print('Product image deleted successfully');
        } catch (e) {
          print('Error deleting image from storage: $e');
          // Don't show error to user as the record was successfully deleted
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error deleting product: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProductImage(String imageUrl) async {
    try {
      // Check if it's a direct path reference or a full URL
      if (!imageUrl.startsWith('http')) {
        // It's a direct path reference
        await FirebaseStorage.instance.ref(imageUrl).delete();
      } else {
        // If it's a full URL, try to extract the path
        final Uri uri = Uri.parse(imageUrl);

        // Two common Firebase Storage URL formats:
        // 1. https://firebasestorage.googleapis.com/v0/b/PROJECT_ID.appspot.com/o/PATH?alt=media&token=TOKEN
        // 2. https://storage.googleapis.com/PROJECT_ID.appspot.com/PATH

        if (uri.host.contains('firebasestorage.googleapis.com')) {
          // Format 1: Extract the path from the 'o' parameter
          final pathSegments = uri.pathSegments;
          if (pathSegments.contains('o') &&
              pathSegments.length > pathSegments.indexOf('o') + 1) {
            final int oIndex = pathSegments.indexOf('o');
            final String encodedPath = pathSegments[oIndex + 1];
            final String decodedPath = Uri.decodeComponent(encodedPath);
            await FirebaseStorage.instance.ref(decodedPath).delete();
          }
        } else if (uri.host.contains('storage.googleapis.com')) {
          // Format 2: Extract path after the domain/bucket
          final pathWithoutQuery = uri.path;
          if (pathWithoutQuery.isNotEmpty) {
            // Remove leading slash if present
            final storagePath = pathWithoutQuery.startsWith('/')
                ? pathWithoutQuery.substring(1)
                : pathWithoutQuery;
            await FirebaseStorage.instance.ref(storagePath).delete();
          }
        } else {
          // Unknown format, try extracting path from different parts of the URL
          print('Unrecognized Firebase Storage URL format: $imageUrl');
          throw Exception('Unrecognized Firebase Storage URL format');
        }
      }
    } catch (e) {
      print('Error in _deleteProductImage: $e');
      rethrow; // Re-throw to be caught by the caller
    }
  }

  void _logout() async {
    await _productsSubscription.cancel(); // 🔥 Cancel Firestore stream
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');

    Get.offAllNamed('/selectRole');
  }

  @override
  void dispose() {
    _productsSubscription.cancel(); // 🔥 Cancel on widget dispose too
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Colors.green,
        title: const Text(
          "Manage Store",
          style: TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Store Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        widget.storeLogo != null && widget.storeLogo!.isNotEmpty
                            ? (widget.storeLogo!.startsWith("http")
                                ? NetworkImage(widget.storeLogo!)
                                : FileImage(File(widget.storeLogo!))
                                    as ImageProvider)
                            : null,
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading store logo: $exception');
                    },
                    child: widget.storeLogo == null || widget.storeLogo!.isEmpty
                        ? const Icon(Icons.store, size: 35, color: Colors.green)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.storeName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(widget.storeAddress,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(widget.phone,
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.storefront, color: Colors.white, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /// Edit Store
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Sellerhomescreen(
                      initialName: '',
                      initialStoreName: widget.storeName,
                      initialStoreAddress: widget.storeAddress,
                      initialCity: '',
                      initialPhone: widget.phone,
                      initialProvince: 'Punjab',
                      initialStoreLogo: widget.storeLogo,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text("Edit Store"),
            ),
            const SizedBox(height: 16),

            /// Product Stats + Add Product
            Row(
              children: [
                _buildStatCard("${_products.length}", "Products"),
                const SizedBox(width: 10),
                _buildStatCard("+", "Add Products", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProductScreen(
                        onProductAdded: _addProduct,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            /// Product List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: productsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  return ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return _buildProductTile(product);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
              Text(label, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.image, color: Colors.white),
      );
    }

    if (imagePath.startsWith("http")) {
      return CircleAvatar(
        backgroundImage: NetworkImage(imagePath),
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading product image: $exception');
        },
      );
    } else {
      try {
        return CircleAvatar(
          backgroundImage: FileImage(File(imagePath)),
          onBackgroundImageError: (exception, stackTrace) {
            print('Error loading product image: $exception');
          },
        );
      } catch (e) {
        print('Error with product image path: $e');
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.broken_image, color: Colors.white),
        );
      }
    }
  }

  Widget _buildProductTile(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: _buildProductImage(product["image"]),
        title: Text(product["name"] ?? "Unnamed Product",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Price: ${product["price"]}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                _editProduct(product);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _deleteProduct(product);
              },
            ),
          ],
        ),
      ),
    );
  }
}
