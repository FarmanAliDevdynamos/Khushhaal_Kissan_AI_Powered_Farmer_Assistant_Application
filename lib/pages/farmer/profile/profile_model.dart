class FarmerProfile {
  final int? id; // Profile ID (nullable for new profiles)
  final String name; // Name of the farmer
  final String phone; // Phone number of the farmer
  final String address; // Address of the farmer
  final String profilePic; // Path to the profile picture

  // Constructor
  FarmerProfile({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.profilePic,
  });

  // Convert a FarmerProfile object into a map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'profilePic': profilePic,
    };
  }

  // Create a FarmerProfile object from a map (SQLite result)
  factory FarmerProfile.fromMap(Map<String, dynamic> map) {
    return FarmerProfile(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      profilePic: map['profilePic'],
    );
  }
}
