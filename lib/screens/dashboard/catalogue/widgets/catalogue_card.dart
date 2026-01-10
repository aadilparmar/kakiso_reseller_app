// lib/screens/dashboard/catalogue/widgets/catalogue_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/catalouge_details_page.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/constants/catalogue_constants.dart';
import 'package:kakiso_reseller_app/screens/dashboard/catalogue/widgets/catalogue_action_buttons.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories_detail_page/widgets/vertical_product_card_categories.dart';

class CatalogueCard extends StatelessWidget {
  final CatalogueModel catalogue;
  final bool isGuideActive;
  final bool isFirstItem;
  final String? activeGuideTool;
  final Animation<double>? pulseAnimation;
  final Function(CatalogueModel) onShare;
  final Function(CatalogueModel) onPdf;
  final Function(CatalogueModel) onCsv;
  final Function(CatalogueModel) onDownload;
  final Function(CatalogueModel) onCollage;
  // 隼 ADDED: Inventory Callback
  final Function(CatalogueModel) onInventory;
  final CatalogueController catalogueController;

  const CatalogueCard({
    Key? key,
    required this.catalogue,
    required this.isGuideActive,
    required this.isFirstItem,
    this.activeGuideTool,
    this.pulseAnimation,
    required this.onShare,
    required this.onPdf,
    required this.onCsv,
    required this.onDownload,
    required this.onCollage,
    // 隼 ADDED
    required this.onInventory,
    required this.catalogueController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double cardOpacity = (isGuideActive && !isFirstItem) ? 0.3 : 1.0;

    return Opacity(
      opacity: cardOpacity,
      child: GestureDetector(
        onTap: () =>
            Get.to(() => CatalogueDetailsPage(catalogueId: catalogue.id)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(UIConstants.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildContent(),
              const Divider(
                height: 14,
                thickness: 0.7,
                color: Color(0xFFE5E7EB),
              ),
              _buildToolsSection(),
              _buildActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ... [Keep _buildHeader, _buildContent, _buildBadge, _buildDeleteButton, _showDeleteConfirmation, _buildToolsSection unchanged] ...

  // PASTED FOR CONTEXT - NO CHANGES IN THESE METHODS
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(UIConstants.cardBorderRadius),
        ),
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.folder_2, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              catalogue.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (catalogue.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                catalogue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildBadge(
                Iconsax.bag_2,
                "${catalogue.products.length} items",
                const Color(0xFFE0F2FE),
                const Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 8),
              _buildBadge(
                Iconsax.star1,
                "My Catalog",
                const Color(0xFFF5F3FF),
                const Color(0xFF6D28D9),
              ),
              const Spacer(),
              Opacity(
                opacity: isGuideActive ? 0.3 : 1.0,
                child: _buildDeleteButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    IconData icon,
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          AutoTranslate(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return CatalogueActionButton(
      icon: Iconsax.trash,
      label: "Delete",
      onTap: () => _showDeleteConfirmation(),
      outlined: true,
      color: Colors.red,
    );
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const AutoTranslate(
          child: Text(
            "Delete Catalog",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        content: AutoTranslate(
          child: Text(
            "Are you sure you want to delete '${catalogue.name}'? This cannot be undone.",
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const AutoTranslate(
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ),
          TextButton(
            onPressed: () {
              VerticalProductCard.sessionAddedToCatalog.removeWhere(
                (key, value) => value == catalogue.name,
              );
              catalogueController.deleteCatalogue(catalogue.id);
              Get.back();
            },
            child: const AutoTranslate(
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Icon(Iconsax.flash_1, color: accentColor, size: 22),
        ),
        const SizedBox(width: 8),
        const AutoTranslate(
          child: Text(
            "Reseller Tools",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF86198F),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [_buildSocialRow(), _buildToolsRow()],
      ),
    );
  }

  Widget _buildSocialRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SocialIconButton(
            icon: Iconsax.message_text,
            color: const Color(0xFF25D366),
            bgColor: const Color(0xFFDCFCE7),
            onTap: () => onShare(catalogue),
            isDimmed: isGuideActive,
          ),
          SocialIconButton(
            icon: Icons.facebook,
            color: const Color(0xFF1877F2),
            bgColor: const Color(0xFFDBEAFE),
            onTap: () => onShare(catalogue),
            isDimmed: isGuideActive,
          ),
          SocialIconButton(
            icon: Iconsax.camera,
            color: const Color(0xFFE1306C),
            bgColor: const Color(0xFFFCE7F3),
            onTap: () => onShare(catalogue),
            isDimmed: isGuideActive,
          ),
          SocialIconButton(
            icon: Icons.share,
            color: const Color(0xFFE1306C),
            bgColor: const Color(0xFFFCE7F3),
            onTap: () => onShare(catalogue),
            isDimmed: isGuideActive,
          ),
        ],
      ),
    );
  }

  Widget _buildToolsRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: [
        // 隼 ADDED: Inventory Button
        _buildActionButton(
          icon: Iconsax.box,
          label: "Inventory",
          onTap: () => onInventory(catalogue),
          bgColor: const Color(0xFFFFF7ED),
          color: const Color(0xFFF97316),
          targetTool: 'inventory_manager',
        ),
        _buildActionButton(
          icon: Iconsax.magicpen,
          label: "Collage",
          onTap: () => onCollage(catalogue),
          bgColor: const Color(0xFFFFFBEB),
          color: const Color(0xFFF59E0B),
          targetTool: 'collage_maker',
        ),
        _buildActionButton(
          icon: Iconsax.document_download,
          label: "Download",
          onTap: () => onDownload(catalogue),
          bgColor: const Color(0xFFFFFBEB),
          color: const Color.fromARGB(255, 11, 105, 245),
          targetTool: 'bulk_downloader',
        ),
        _buildActionButton(
          icon: Iconsax.document_text,
          label: "CSV",
          onTap: () => onCsv(catalogue),
          bgColor: const Color(0xFFECFDF5),
          color: const Color(0xFF059669),
          targetTool: 'csv_builder_pro',
        ),
        _buildActionButton(
          icon: Iconsax.document_code,
          label: "PDF",
          onTap: () => onPdf(catalogue),
          bgColor: const Color(0xFFF5F3FF),
          color: const Color(0xFF7C3AED),
          targetTool: 'pdf_generator',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color bgColor,
    required Color color,
    required String targetTool,
  }) {
    bool isTarget = activeGuideTool == targetTool;
    bool isDimmed = isGuideActive && !isTarget;

    return CatalogueActionButton(
      icon: icon,
      label: label,
      onTap: onTap,
      bgColor: bgColor,
      color: color,
      isTarget: isTarget,
      isDimmed: isDimmed,
      pulseAnimation: isTarget ? pulseAnimation : null,
    );
  }
}
