import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

/// Steps: 1: Cart, 2: Address, 3: Review, 4: Payment
class CheckoutStepHeader extends StatelessWidget {
  final int currentStep; // 1,2,3,4

  const CheckoutStepHeader({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Cart', 'Address', 'Review', 'Payment'];

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _stepChip(text: steps[i], index: i + 1, currentStep: currentStep),
          if (i != steps.length - 1) _stepDivider(),
        ],
      ],
    );
  }

  Widget _stepChip({
    required String text,
    required int index,
    required int currentStep,
  }) {
    final bool isDone = index < currentStep;
    final bool isActive = index == currentStep;

    Color circleColor;
    IconData icon;
    if (isDone) {
      circleColor = accentColor;
      icon = Icons.check;
    } else if (isActive) {
      circleColor = accentColor;
      icon = Iconsax.activity; // little pulse icon
    } else {
      circleColor = Colors.grey.shade300;
      icon = Icons.circle_outlined;
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: circleColor,
          child: Icon(icon, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDone || isActive ? accentColor : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _stepDivider() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 1,
        color: Colors.grey.shade300,
      ),
    );
  }
}
