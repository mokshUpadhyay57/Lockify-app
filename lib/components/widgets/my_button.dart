import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';


class MyButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final void Function()? onTap;

  const MyButton({super.key, required this.text, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryPurple.withOpacity(0.25), AppColors.primaryPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.white, size: 20),
              const SizedBox(width: 8), // Spacing between icon and text
            ],
            Text(
              text,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

