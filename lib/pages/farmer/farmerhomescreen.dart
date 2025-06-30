import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:khushhal_kisan_app/pages/farmer/ChatAI/ai_kissan.dart';
import 'package:khushhal_kisan_app/pages/farmer/Crop/my_crops.dart';
import 'package:khushhal_kisan_app/pages/farmer/diagnosis_page/crop_analyzer.dart';
import 'package:khushhal_kisan_app/pages/farmer/store/storescreen.dart';
import 'package:khushhal_kisan_app/pages/farmer/weather/weatherpage.dart';
import 'package:khushhal_kisan_app/pages/farmer/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Farmerhomescreen extends StatefulWidget {
  const Farmerhomescreen({super.key});

  @override
  State<Farmerhomescreen> createState() => _FarmerhomescreenState();
}

class _FarmerhomescreenState extends State<Farmerhomescreen> {
  int _selectedIndex = 0;
  String temperature = "Loading...";
  String weatherCondition = "";
  String city = "Taxila";
  String phone = ""; // Add this variable to store the phone number

  final List<String> sliderImages = [
    "assets/images/slider1.jpg",
    "assets/images/slider2.jpg",
    "assets/images/slider3.jpg",
    "assets/images/slider4.jpg",
  ];

  @override
  void initState() {
    super.initState();
    fetchWeather();
    fetchPhoneNumber(); // Fetch the phone number
  }

  Future<void> fetchWeather() async {
    const String apiKey = "9e4facc3f437949979cb7ec5aa9f551b";
    final String url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            temperature = "${data['main']['temp'].toString()}°C";
            weatherCondition = data['weather'][0]['description'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            temperature = "Error";
            weatherCondition = "Could not fetch";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          temperature = "Error";
          weatherCondition = "Check Internet";
        });
      }
    }
  }

  Future<void> fetchPhoneNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      if (mounted) {
        setState(() {
          phone = user.phoneNumber!;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          phone = "Unknown";
        });
      }
    }
  }

  int _currentIndex = 0;

  Widget buildSlider() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.90,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: sliderImages.map((imagePath) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.fill,
                  width: double.infinity,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: sliderImages.asMap().entries.map((entry) {
            return Container(
              width: _currentIndex == entry.key ? 12.0 : 8.0,
              height: _currentIndex == entry.key ? 12.0 : 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == entry.key
                    ? Colors.green.shade700
                    : Colors.grey.shade400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    _pages.clear();
    _pages.add(
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              const SizedBox(height: 10),
              buildSlider(),
              const SizedBox(height: 15),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: () => Get.to(() => WeatherScreen()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.green.shade200, Colors.orange.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Weather",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              temperature,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              city,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              weatherCondition,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.wb_cloudy,
                          size: 64,
                          color: Colors.orange.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "General Crops Suggestions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    CropCard(
                      name: "Lemon",
                      imagePath: "assets/images/lemon.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Mango",
                      imagePath: "assets/images/mango.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Guava",
                      imagePath: "assets/images/guava.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Orange",
                      imagePath: "assets/images/orange.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Peach",
                      imagePath: "assets/images/peach.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Wheat",
                      imagePath: "assets/images/wheat.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Sugarcane",
                      imagePath: "assets/images/sugarcane.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Cotton",
                      imagePath: "assets/images/cotton.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Rice",
                      imagePath: "assets/images/rice.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Maize",
                      imagePath: "assets/images/maize.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Potato",
                      imagePath: "assets/images/potato.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Tomato",
                      imagePath: "assets/images/tomato.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Onion",
                      imagePath: "assets/images/onion.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Garlic",
                      imagePath: "assets/images/garlic.jpg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Cauliflower",
                      imagePath: "assets/images/cauliflower.jpeg",
                      cropDetails: cropDetails,
                    ),
                    CropCard(
                      name: "Spinach",
                      imagePath: "assets/images/spinach.jpg",
                      cropDetails: cropDetails,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFd1f7c4),
                      Color(0xFFa5e3b9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange.shade700,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "                                          :آج کی تجویز",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "کیڑوں سے بچاؤ کے لیے قدرتی طریقے اور ادویات استعمال کریں، بغیر ضرورت کے زہریلی دوائیں نہ استعمال کریں۔",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _pages.addAll([
      const Center(child: Text("Diagnosis Page")),
      const Center(child: Text("Store Page")), // Placeholder for store page
      const Center(child: Text("Chat AI Page")), // Placeholder for chat page
      const Center(child: Text("Profile Page")), // Placeholder for profile page
    ]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 55),
            const SizedBox(width: 8),
            const Text(
              'Khushhaal Kissan',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud, color: Colors.white),
            onPressed: () {
              Get.to(() => WeatherScreen());
            },
          ),
        ],
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade700,
              ),
              child: const Center(
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();

                // Clear the stored role
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('userRole');

                // Navigate to the role selection screen
                Get.offAllNamed('/selectRole');
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 1) {
                  // Navigate to DiagnosisPage using Get.to() for complete navigation
                  Get.to(() => const CropAnalyzer());
                } else if (index == 2) {
                  // Navigate to StoreScreen using Get.to() for complete navigation
                  Get.to(() => const StoreScreen());
                } else if (index == 3) {
                  // Navigate to FarmerChatScreen for "Chat AI"
                  Get.to(() => FarmerChatScreen());
                } else if (index == 4) {
                  // Navigate to ProfileScreen for "Profile"
                  Get.to(() => ProfileScreen(loggedInPhone: phone));
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.yellow,
              unselectedItemColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.eco), label: "Diagnosis"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.store), label: "Store"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat), label: "Chat AI"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: "Profile"),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: FloatingActionButton(
              backgroundColor: Colors.green.shade900,
              onPressed: () {
                // Navigate to StoreScreen using Get.to() for complete navigation
                Get.to(() => const StoreScreen());
              },
              child: const Icon(Icons.store, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any ongoing operations or listeners here
    super.dispose();
  }
}
