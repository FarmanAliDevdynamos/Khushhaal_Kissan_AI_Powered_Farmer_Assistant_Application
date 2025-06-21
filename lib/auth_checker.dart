// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:khushhal_kisan_app/pages/farmer/farmerhomescreen.dart';
// // import 'package:khushhal_kisan_app/pages/login_page.dart';
// // import 'package:khushhal_kisan_app/pages/seller/sellerhomescreen.dart';

// // class AuthChecker extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return StreamBuilder<User?>(
// //       stream: FirebaseAuth.instance.authStateChanges(),
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Scaffold(
// //             body: Center(child: CircularProgressIndicator()),
// //           );
// //         }

// //         if (snapshot.hasData && snapshot.data != null) {
// //           User user = snapshot.data!;
// //           return FutureBuilder<String>(
// //             future: getUserRole(user.uid),
// //             builder: (context, roleSnapshot) {
// //               if (roleSnapshot.connectionState == ConnectionState.waiting) {
// //                 return const Scaffold(
// //                   body: Center(child: CircularProgressIndicator()),
// //                 );
// //               }

// //               if (roleSnapshot.hasData) {
// //                 String role = roleSnapshot.data!;
// //                 if (role == "Farmer") {
// //                   return Farmerhomescreen();
// //                 } else if (role == "Seller") {
// //                   return Sellerhomescreen();
// //                 }
// //               }

// //               return LoginPage(role: role); // Default: If role not found, go to login
// //             },
// //           );
// //         } else {
// //           return LoginPage(role: role); // If user is not logged in, go to login screen
// //         }
// //       },
// //     );
// //   }

// //   Future<String> getUserRole(String uid) async {
// //     try {
// //       DocumentSnapshot userDoc =
// //           await FirebaseFirestore.instance.collection('users').doc(uid).get();

// //       if (userDoc.exists) {
// //         return userDoc['role'] ?? "Unknown"; // Get the role from Firestore
// //       } else {
// //         return "Unknown"; // If user doc doesn’t exist
// //       }
// //     } catch (e) {
// //       print("Error fetching role: $e");
// //       return "Unknown";
// //     }
// //   }
// // }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:khushhal_kisan_app/pages/farmer/farmerhomescreen.dart';
// import 'package:khushhal_kisan_app/pages/homepage.dart';
// import 'package:khushhal_kisan_app/pages/login_page.dart';
// import 'package:khushhal_kisan_app/pages/seller/sellerhomescreen.dart';


// class AuthChecker extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (snapshot.hasData && snapshot.data != null) {
//           User user = snapshot.data!;
//           return FutureBuilder<String>(
//             future: getUserRole(user.uid),
//             builder: (context, roleSnapshot) {
//               if (roleSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Scaffold(
//                   body: Center(child: CircularProgressIndicator()),
//                 );
//               }

//               if (roleSnapshot.hasError || !roleSnapshot.hasData) {
//                 return LoginPage(role: role); // 🔥 Default to login if role fetch fails
//               }

//               String role = roleSnapshot.data!;

//               // Navigate to role selection if role is missing or invalid
//               if (role.isEmpty || role == "Unknown") {
//                 return Homepage(userId: user.uid);
//               } else if (role == "Farmer") {
//                 return Farmerhomescreen();
//               } else if (role == "Seller") {
//                 return Sellerhomescreen();
//               } else {
//                 return LoginPage(role: role); // 🔥 Handle unexpected roles
//               }
//             },
//           );
//         } else {
//           return LoginPage(role: role); // 🔥 User not logged in → Go to login
//         }
//       },
//     );
//   }

//   Future<String> getUserRole(String uid) async {
//     try {
//       DocumentSnapshot userDoc =
//           await FirebaseFirestore.instance.collection('users').doc(uid).get();

//       if (userDoc.exists && userDoc.data() != null) {
//         return userDoc.get('role') ?? "Unknown"; // Get role from Firestore
//       } else {
//         return "Unknown"; // If no user document exists
//       }
//     } catch (e) {
//       print("Error fetching role: $e");
//       return "Unknown"; // Handle errors gracefully
//     }
//   }
// }
