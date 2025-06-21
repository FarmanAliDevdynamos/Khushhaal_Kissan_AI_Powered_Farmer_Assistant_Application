import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_model.dart';
import 'profile_db_helper.dart';

class ProfileScreen extends StatefulWidget {
  final String loggedInPhone; // Add this

  const ProfileScreen({super.key, required this.loggedInPhone}); // Require it

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  File? _image;

  FarmerProfile? profile;
  bool isEditing = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final dbHelper = ProfileDbHelper();
    final fetchedProfile =
        await dbHelper.getProfileByPhone(widget.loggedInPhone);

    if (fetchedProfile != null) {
      setState(() {
        profile = fetchedProfile;
        nameController.text = profile!.name;
        addressController.text = profile!.address;
        _image = File(profile!.profilePic);
        isEditing = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final pickedSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Image Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (pickedSource != null) {
      final pickedImage = await picker.pickImage(source: pickedSource);
      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select a picture."),
        ),
      );
      return;
    }

    final newProfile = FarmerProfile(
      id: profile?.id,
      name: nameController.text,
      phone: widget.loggedInPhone, // Use logged-in phone
      address: addressController.text,
      profilePic: _image!.path,
    );

    final dbHelper = ProfileDbHelper();
    if (profile == null) {
      await dbHelper.insertProfile(newProfile);
    } else {
      await dbHelper.updateProfile(newProfile);
    }

    setState(() {
      profile = newProfile;
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved successfully.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Farmer Profile",
          style: TextStyle(color: Colors.teal),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing ? _buildEditForm() : _buildProfileView(),
      ),
    );
  }

  Widget _buildEditForm() {
    return ListView(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _image != null ? FileImage(_image!) : null,
              backgroundColor: Colors.grey.shade200,
              child: _image == null
                  ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Name"),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        TextField(
          controller: addressController,
          decoration: const InputDecoration(labelText: "Address"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text("Save Profile"),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 80,
          backgroundImage: FileImage(File(profile!.profilePic)),
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(height: 20),
        Text(
          profile!.name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone, color: Colors.teal, size: 22),
            const SizedBox(width: 6),
            Text(
              profile!.phone,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.teal, size: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                profile!.address,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              isEditing = true;
            });
          },
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text("Edit Profile"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
