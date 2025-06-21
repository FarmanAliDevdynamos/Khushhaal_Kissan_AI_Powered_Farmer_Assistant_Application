import 'package:flutter/material.dart';
import 'package:khushhal_kisan_app/pages/farmer/Crop/cropdetailscreen.dart';

class CropCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isHighlighted;
  final Map<String, Map<String, String>> cropDetails;

  const CropCard({
    super.key,
    required this.name,
    required this.imagePath,
    this.isHighlighted = false,
    required this.cropDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration:
                const Duration(milliseconds: 1000), // Slower animation
            pageBuilder: (context, animation, secondaryAnimation) =>
                CropDetailsScreen(
              cropName: name,
              imagePath: imagePath,
              cropDetails: cropDetails[name] ?? {},
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap the crop image with a Hero widget
            Hero(
              tag: name, // Unique tag for each crop
              child: CircleAvatar(
                backgroundImage: AssetImage(imagePath),
                radius: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                color: isHighlighted ? Colors.white : Colors.green.shade800,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
