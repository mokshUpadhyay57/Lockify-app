import 'package:flutter/material.dart';
import 'package:lockify/utils/colors.dart';

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;
  final Widget? chart;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueColor = AppColors.errorRed,
    this.chart,
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.grey),
                  ),
                ),
              ],
            ),
            if (chart != null) ...[
              const SizedBox(height: 20),
              chart!,
            ],
          ],
        ),
      ),
    );
  }
}

