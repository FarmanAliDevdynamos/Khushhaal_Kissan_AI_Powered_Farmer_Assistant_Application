import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:khushhal_kisan_app/firebase_options.dart';
import 'package:khushhal_kisan_app/pages/farmer/farmerhomescreen.dart';
import 'package:khushhal_kisan_app/pages/homepage.dart';
import 'package:khushhal_kisan_app/pages/seller/sellerdashboard.dart';
import 'package:khushhal_kisan_app/pages/seller/sellerhomescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole'); // Retrieve the stored role

    if (userRole == "Farmer") {
      return const Farmerhomescreen(); // Navigate to Farmer Dashboard
    } else if (userRole == "Seller") {
      // Check if store information exists in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          // If store information exists, navigate to SellerManageStore
          final data = doc.data()!;
          return SellerManageStore(
            storeName: data['storeName'] ?? '',
            storeAddress: data['storeAddress'] ?? '',
            phone: data['phone'] ?? '',
            storeLogo: data['storeLogo'] ?? '',
            products: [], // Fetch products if needed
          );
        }
      }
      // If no store information exists, navigate to Sellerhomescreen
      return const Sellerhomescreen();
    } else {
      return const Homepage(); // Default to Homepage if no role is stored
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return GetMaterialApp(
          title: 'Khushhal Kisan',
          theme: ThemeData(primarySwatch: Colors.green),
          home: snapshot.data, // Set the initial screen
          routes: {
            '/selectRole': (context) =>
                const Homepage(), // Role selection screen
            '/farmerDashboard': (context) =>
                const Farmerhomescreen(), // Farmer dashboard
            '/sellerDashboard': (context) => const SellerManageStore(
                  storeName: '', // Fetch from Firestore if needed
                  storeAddress: '',
                  phone: '',
                  storeLogo: '', // Fetch from Firestore or pass a default value
                  products: [],
                ), // Seller dashboard
          },
        );
      },
    );
  }
}
