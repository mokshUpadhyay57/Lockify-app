import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';


class SignatureBox extends StatelessWidget {
  final SignatureController controller;

  const SignatureBox({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Signature Drawing Area
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.white,
          ),
          child: Signature(
            controller: controller,
            backgroundColor: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),

        // Instruction Text
        Center(
          child: Text(
            "Sign here",
            style: TextStyle(
              color: AppColors.grey600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

