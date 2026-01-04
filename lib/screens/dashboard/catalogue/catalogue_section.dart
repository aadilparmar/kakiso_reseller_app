import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalogue_section_content.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:kakiso_reseller_app/models/user.dart';

/// Main entry point for the Catalogue Section
/// Wraps the content with ShowCaseWidget for onboarding tours
class CatalogueSection extends StatelessWidget {
  final UserData userData;

  const CatalogueSection({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => CatalogueSectionContent(userData: userData),
      autoPlay: false,
      blurValue: 1,
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 300),
    );
  }
}
