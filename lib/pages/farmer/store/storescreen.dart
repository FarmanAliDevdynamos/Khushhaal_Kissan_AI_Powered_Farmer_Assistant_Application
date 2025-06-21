import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get collection of all sellers
      final sellersSnapshot =
          await FirebaseFirestore.instance.collection('sellers').get();

      List<Map<String, dynamic>> allProducts = [];

      // Loop through each seller
      for (var seller in sellersSnapshot.docs) {
        final sellerId = seller.id;
        final sellerData = seller.data();

        // Get all products for this seller
        final productsSnapshot = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .collection('products')
            .get();

        // Add seller information to each product
        final sellerProducts = productsSnapshot.docs.map((doc) {
          final productData = doc.data();
          return {
            ...productData,
            'id': doc.id,
            'sellerId': sellerId,
            'sellerName': sellerData['storeName'] ?? 'Unknown Store',
            'sellerAddress': sellerData['storeAddress'] ?? '',
          };
        }).toList();

        allProducts.addAll(sellerProducts);
      }

      setState(() {
        _products = allProducts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    if (_selectedCategory == 'All') {
      return _products;
    }
    return _products
        .where((product) =>
            product['productType'] == _selectedCategory ||
            (product['medicineType'] == _selectedCategory &&
                product['productType'] == 'Medicines'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Buy Seeds & Medicines',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.search, color: Colors.white),
          //   onPressed: () {
          //     // Implement search functionality
          //   },
          // ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Category Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _categoryChip(Icons.category, "All"),
                _categoryChip(Icons.eco, "Seeds"),
                _categoryChip(Icons.grass, "Fertilizers"),
                _categoryChip(Icons.medical_services, "Medicines"),
                _categoryChip(Icons.bug_report, "Insecticides"),
                _categoryChip(Icons.spa, "Fungicides"),
                _categoryChip(Icons.grass_outlined, "Herbicides"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Refresh Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _fetchProducts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                : filteredProducts.isEmpty
                    ? const Center(child: Text('No products found'))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GridView.builder(
                          itemCount: filteredProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.7,
                          ),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _productCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(IconData icon, String label) {
    final bool isSelected = _selectedCategory == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: Colors.green.shade200,
        backgroundColor: Colors.grey.shade200,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = label;
          });
        },
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade800 : Colors.black87,
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product['image'] != null
                  ? _buildProductImage(product['image'])
                  : Container(
                      height: 90,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              product['name'] ?? 'Unnamed Product',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Description
            Text(
              product['description'] ?? 'No description available',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Store name
            Text(
              'Store: ${product['sellerName'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Price + Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs. ${product['price'] ?? '0'}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _viewProductDetails(context, product);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('View'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    // Check if this is a full URL or a Firebase Storage reference
    if (imageUrl.startsWith('http')) {
      // Already a full URL, use it directly
      return Image.network(
        imageUrl,
        height: 90,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(
            height: 90,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 90,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.green,
              ),
            ),
          );
        },
      );
    } else {
      // This is a Firebase Storage reference path, construct the URL
      try {
        // Get the reference and download URL
        return FutureBuilder<String>(
          future: FirebaseStorage.instance.ref(imageUrl).getDownloadURL(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 90,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              print('Error getting download URL: ${snapshot.error}');
              return Container(
                height: 90,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            }

            // We have the download URL, display the image
            return Image.network(
              snapshot.data!,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 90,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.error, color: Colors.red),
                );
              },
            );
          },
        );
      } catch (e) {
        print('Exception when processing image URL: $e');
        return Container(
          height: 90,
          width: double.infinity,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    }
  }

  Widget _buildLargeProductImage(String imageUrl) {
    // Check if this is a full URL or a Firebase Storage reference
    if (imageUrl.startsWith('http')) {
      // Already a full URL, use it directly
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: const Icon(Icons.error, color: Colors.red, size: 50),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.green,
              ),
            ),
          );
        },
      );
    } else {
      // This is a Firebase Storage reference path, construct the URL
      try {
        // Get the reference and download URL
        return FutureBuilder<String>(
          future: FirebaseStorage.instance.ref(imageUrl).getDownloadURL(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              print('Error getting download URL: ${snapshot.error}');
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image,
                    color: Colors.grey, size: 50),
              );
            }

            // We have the download URL, display the image
            return Image.network(
              snapshot.data!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.error, color: Colors.red, size: 50),
                );
              },
            );
          },
        );
      } catch (e) {
        print('Exception when processing image URL: $e');
        return Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        );
      }
    }
  }

  void _viewProductDetails(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product['image'] != null
                      ? _buildLargeProductImage(product['image'])
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image,
                              color: Colors.grey, size: 50),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Product Title
              Text(
                product['name'] ?? 'Unnamed Product',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                'Rs. ${product['price'] ?? '0'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(product['description'] ?? 'No description available'),
              const SizedBox(height: 16),

              // Product Details
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Type: ${product['productType'] ?? 'Not specified'}'),
              if (product['medicineType'] != null)
                Text('Medicine Type: ${product['medicineType']}'),
              const SizedBox(height: 16),

              // Store Information
              const Text(
                'Store Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Store: ${product['sellerName'] ?? 'Unknown Store'}'),
              Text(
                  'Address: ${product['sellerAddress'] ?? 'No address provided'}'),
              const SizedBox(height: 24),

              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implement add to cart functionality
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product added to cart!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
