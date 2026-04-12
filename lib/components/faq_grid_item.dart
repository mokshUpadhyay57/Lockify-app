import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'faq_item.dart';


class FAQGridItem extends StatelessWidget {
  final FAQItem faqItem;

  const FAQGridItem({super.key, required this.faqItem});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Handle navigation to specific FAQ section
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black12,
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(faqItem.iconPath, width: 40, height: 40),
            const SizedBox(height: 10),
            Text(
              faqItem.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

