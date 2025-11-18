// lib/screens/dashboard/tools/widgets/recipient_input.dart
import 'package:flutter/material.dart';

class RecipientInput extends StatelessWidget {
  final List<Map<String, String>> countryCodes;
  final String selectedCountry;
  final ValueChanged<String> onCountryChanged;
  final TextEditingController phoneController;
  final VoidCallback onAdd;

  const RecipientInput({
    super.key,
    required this.countryCodes,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.phoneController,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCountry,
                  items: countryCodes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['code'],
                          child: Row(
                            children: [
                              Text(
                                c['label']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c['code']!,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    onCountryChanged(v);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Enter phone number',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB2A7E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
