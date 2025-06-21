import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';

class FirestoreSlider extends StatefulWidget {
  const FirestoreSlider({super.key});

  @override
  _FirestoreSliderState createState() => _FirestoreSliderState();
}

class _FirestoreSliderState extends State<FirestoreSlider> {
  List<Map<String, dynamic>> posters = [];

  @override
  void initState() {
    super.initState();
    fetchPosters();
  }

  Future<void> fetchPosters() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('farmer_schemes')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      posters = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return posters.isEmpty
        ? Center(child: CircularProgressIndicator())
        : CarouselSlider(
            options: CarouselOptions(autoPlay: true, enlargeCenterPage: true),
            items: posters.map((poster) {
              Uint8List imageBytes = base64Decode(poster['image_base64']);
              return Container(
                margin: EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Stack(
                    children: [
                      Image.memory(imageBytes, fit: BoxFit.cover, width: 1000),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Text(
                          poster['title'],
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
  }
}
