import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushhal_kisan_app/controller/role_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:khushhal_kisan_app/pages/farmer/farmerhomescreen.dart';
import 'package:khushhal_kisan_app/pages/login_page.dart';
import 'package:khushhal_kisan_app/pages/seller/sellerhomescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  Future<void> _saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role); // Save the role locally
  }

  @override
  Widget build(BuildContext context) {
    final RoleController roleController = Get.put(RoleController());

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.2),
              const Text(
                "Choose Your Role",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  roleController.setRole("Farmer");
                },
                child: Obx(() => RoleCard(
                      title: "Farmer",
                      description:
                          "Weather, Buy Seeds, Diseases\nSolution and more",
                      imagePath: "assets/images/farmer1.jpg",
                      isSelected: roleController.selectedRole.value == "Farmer",
                    )),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  roleController.setRole("Seller");
                },
                child: Obx(() => RoleCard(
                      title: "Seller",
                      description:
                          "Sell seeds, fertilizers,\npesticides and more",
                      imagePath: "assets/images/store.jpg",
                      isSelected: roleController.selectedRole.value == "Seller",
                    )),
              ),
              const SizedBox(height: 70),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (roleController.selectedRole.value.isNotEmpty) {
                    // Save the selected role
                    await _saveUserRole(roleController.selectedRole.value);

                    // Check if the user is already authenticated
                    if (FirebaseAuth.instance.currentUser != null) {
                      if (roleController.selectedRole.value == "Farmer") {
                        Get.to(() => const Farmerhomescreen()); // Navigate to Farmer's Home Screen
                      } else if (roleController.selectedRole.value == "Seller") {
                        Get.to(() => const Sellerhomescreen()); // Navigate to Seller's Home Screen
                      }
                    } else {
                      Get.to(() => LoginPage(role: roleController.selectedRole.value));
                    }
                  } else {
                    Get.snackbar("Error", "Please select a role before proceeding.");
                  }
                },
                child: const Text(
                  "Next >",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final bool isSelected;

  const RoleCard({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isSelected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[100] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.green[700]! : Colors.green,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(imagePath, width: 85, height: 90),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
