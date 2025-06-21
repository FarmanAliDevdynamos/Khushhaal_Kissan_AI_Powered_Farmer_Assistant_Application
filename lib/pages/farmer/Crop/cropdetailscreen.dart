import 'package:flutter/material.dart';

class CropDetailsScreen extends StatelessWidget {
  final String cropName;
  final String imagePath;
  final Map<String, String> cropDetails;

  const CropDetailsScreen({
    super.key,
    required this.cropName,
    required this.imagePath,
    required this.cropDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        title: Text(
          cropName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Crop Image
            Hero(
              tag: cropName,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Crop Name
            Text(
              cropName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Detail Cards
            _buildDetailCard(
                "🌡️ مناسب درجہ حرارت کی حد", cropDetails['temperature']),
            _buildDetailCard("💧 پانی دینے کی تعدد", cropDetails['watering']),
            _buildDetailCard("🧪 کھاد کے مشورے", cropDetails['fertilizer']),
            _buildDetailCard("🐛 عام بیماریاں/کیڑے", cropDetails['diseases']),
            _buildDetailCard("📅 بیج بونے کا وقت", cropDetails['sowing']),
            _buildDetailCard("📅 فصل کاٹنے کا وقت", cropDetails['harvesting']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String? value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco, color: Colors.green, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value ?? 'معلومات دستیاب نہیں',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
