import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String username;
  final bool isOnline;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.username,
    this.isOnline = false,
  });


String getInitial(String name) {
    if (name.isNotEmpty) {
      return name[0].toUpperCase(); // Get the first letter and convert it to uppercase
    }
    return '';
 // Default initial if the name is empty
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.black,
            child: Text(
              getInitial(name),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('@$username', style: const TextStyle(color: Colors.deepOrangeAccent)),
              const SizedBox(width: 8),
              if (isOnline)
                Row(
                  children: const [
                    Text(
                      '| Online now',
                      style: TextStyle(
                        color: AppColors.onlineGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: const [
                    Text(
                      '| Offline',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],      
                ),
            ],
          ),
        ],
      ),
    );
  }
}

