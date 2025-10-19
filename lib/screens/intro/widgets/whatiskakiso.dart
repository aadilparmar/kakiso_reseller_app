import 'package:flutter/material.dart';

// Assuming these color definitions are available in your main file or a theme.
// Defining them here for self-containment.
const Color accentColor = Color(0xFFE91E63); // Vibrant Pink
const Color purpleHeaderColor = Color(0xFF4A317E); // Deep Purple
const Color lightPurpleBackground = Color(
  0xFFF7F4F9,
); // A light background color

class KWhatIsDropshipping extends StatelessWidget {
  final Color accentColor;
  final Color purpleHeaderColor;

  const KWhatIsDropshipping({
    super.key,
    required this.accentColor,
    required this.purpleHeaderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title: "What is Dropshipping?"
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black, // Default color for "What is"
              ),
              children: <TextSpan>[
                const TextSpan(text: 'What is '),
                TextSpan(
                  text: 'Dropshipping?',
                  style: TextStyle(
                    color: accentColor, // Pink for "Dropshipping?"
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Stack for Circles and the Connecting Line
          Stack(
            alignment: Alignment.center,
            children: [
              // 1. The connecting line, drawn behind the circles.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Container(height: 2, color: accentColor),
              ),
              // 2. Row containing only the image circles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildImageCircle('assets/images/icons/icon1.png'),
                  _buildImageCircle('assets/images/icons/icon2.png'),
                  _buildImageCircle('assets/images/icons/icon3.png'),
                  _buildImageCircle('assets/images/icons/icon4.png'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row for Text Labels below the circles
          // FIX: Removed 'const' keyword because _buildLabel is not a const function.
          Row(
            children: [
              _buildLabel('Product ready'),
              SizedBox(width: 15),
              _buildLabel('Supplier'),
              SizedBox(width: 15),
              _buildLabel('Product shipping'),
              SizedBox(width: 15),
              _buildLabel('Make a Profit'),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for the image circle
  Widget _buildImageCircle(String imagePath) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lightPurpleBackground, // Background color to hide the line
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          // Using local asset path
          imagePath,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported, color: Colors.grey);
          },
        ),
      ),
    );
  }

  // Helper widget for the text label
  Widget _buildLabel(String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color.fromARGB(255, 66, 64, 150),
        ),
      ),
    );
  }
}
