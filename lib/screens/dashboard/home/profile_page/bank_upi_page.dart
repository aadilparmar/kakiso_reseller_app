import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

class BankUpiPage extends StatefulWidget {
  const BankUpiPage({super.key});

  @override
  State<BankUpiPage> createState() => _BankUpiPageState();
}

class _BankUpiPageState extends State<BankUpiPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AutoTranslate(
          child: Text(
            "Bank & UPI Details",
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Bank Account Details"),
                      _buildCard([
                        _buildTextField(
                          "Account Number",
                          _accController,
                          Iconsax.card,
                          isNumber: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "IFSC Code",
                          _ifscController,
                          Iconsax.bank,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Account Holder Name",
                          _nameController,
                          Iconsax.user,
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle("UPI Details"),
                      _buildCard([
                        _buildTextField(
                          "UPI ID (e.g. name@okhdfcbank)",
                          _upiController,
                          Iconsax.scan,
                        ),
                      ]),
                      // Extra padding at bottom for scrolling past FAB/Buttons if needed
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: Add your backend save logic here
                      Get.snackbar(
                        "Success",
                        "Bank details saved successfully!",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const AutoTranslate(
                    child: Text(
                      "Save Details",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: AutoTranslate(
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF212121),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    String labelTextString,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        // FIX: Removed 'labelText: labelTextString' to avoid conflict
        label: AutoTranslate(child: Text(labelTextString)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Field cannot be empty';
        return null;
      },
    );
  }
}
