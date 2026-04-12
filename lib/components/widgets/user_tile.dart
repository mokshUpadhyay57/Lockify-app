import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';


class UserTile extends StatelessWidget {
  final String text; // User's name or email
  final String? subtitle; // Optional subtitle (e.g., last message)
  final String? avatarUrl; // Optional avatar image URL
  final void Function()? onTap;

const UserTile({
    super.key,
    required this.text,
    this.subtitle,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey,
              blurRadius: 6.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24.0,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null, // Use avatarUrl if provided
              backgroundColor: AppColors.grey300,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: 16.0),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: AppColors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            // Optional trailing icon
            const Icon(Icons.arrow_forward_ios, size: 16.0, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}

