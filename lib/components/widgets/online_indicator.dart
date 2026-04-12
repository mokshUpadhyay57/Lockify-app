import 'package:lockify/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lockify/services/auth/auth_service.dart';


class OnlineIndicator extends StatelessWidget {
  final String phone;
  final double size;
  final double borderWidth;

  const OnlineIndicator({
    super.key,
    required this.phone,
    this.size = 14,
    this.borderWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final normalized = authService.normalizePhone(phone);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        bool isOnline = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          isOnline = (snapshot.data!.docs.first.data() as Map<String, dynamic>)['isOnline'] ?? false;
        }

        if (!isOnline) return const SizedBox.shrink();

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.onlineGreen,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: borderWidth),
          ),
        );
      },
    );
  }
}

