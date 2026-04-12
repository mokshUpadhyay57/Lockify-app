import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';


class SubscriptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;

const SubscriptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueColor = AppColors.errorRed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Chart Placeholder",
                style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

