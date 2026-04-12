import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';


class EmptyState extends StatelessWidget {
const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Image.asset('assets/images/empty_state.png', width: 120),
          const SizedBox(height: 20),
          const Text(
            'No public channels or groups started by you yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

