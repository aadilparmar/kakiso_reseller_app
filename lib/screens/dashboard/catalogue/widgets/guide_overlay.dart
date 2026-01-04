import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';

class GuideOverlay extends StatelessWidget {
  final String toolId;
  final VoidCallback onDismiss;

  const GuideOverlay({Key? key, required this.toolId, required this.onDismiss})
    : super(key: key);

  GuideContent _getGuideContent() {
    switch (toolId) {
      case 'collage_maker':
        return GuideContent(
          title: "Collage Maker",
          message:
              "Tap the 'Collage' button on any catalog below to start creating amazing images!",
          icon: Iconsax.magicpen,
        );
      case 'pdf_generator':
        return GuideContent(
          title: "PDF Generator",
          message:
              "Tap the 'PDF' button on a catalog to generate a professional brochure.",
          icon: Iconsax.document_text,
        );
      case 'csv_builder_pro':
        return GuideContent(
          title: "CSV Export",
          message:
              "Tap 'CSV' to download a file ready for Amazon, Shopify, or Excel.",
          icon: Iconsax.document_code,
        );
      case 'bulk_downloader':
        return GuideContent(
          title: "Bulk Download",
          message: "Tap 'Download' to save all product images to your gallery.",
          icon: Iconsax.document_download,
        );
      case 'smart_catalog':
        return GuideContent(
          title: "Smart Catalog",
          message: "Click 'New Catalog' or manage existing ones here.",
          icon: Iconsax.folder_add,
        );
      default:
        return GuideContent(
          title: "Tool Guide",
          message: "Select a catalog to use this tool.",
          icon: Iconsax.info_circle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _getGuideContent();

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, val, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - val)),
              child: Opacity(opacity: val, child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(content.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoTranslate(
                        child: Text(
                          content.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AutoTranslate(
                        child: Text(
                          content.message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const AutoTranslate(
                            child: Text(
                              "Got it!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuideContent {
  final String title;
  final String message;
  final IconData icon;

  GuideContent({
    required this.title,
    required this.message,
    required this.icon,
  });
}
