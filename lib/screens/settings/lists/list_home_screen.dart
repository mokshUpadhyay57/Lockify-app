import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lockify/screens/settings/lists/list_options.dart';
import 'dart:ui';
 // Import for ImageFilter

class ListHomeScreen extends StatelessWidget {
  const ListHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the platform is iOS
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lists',
          style: TextStyle(fontSize: 18, color: AppColors.white),
          
        ),
        toolbarHeight: 50,
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: isIOS ? 0 : 4,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // Increased horizontal padding
        itemCount: listOptions.length,
        itemBuilder: (context, index) {
          final option = listOptions[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(15), // Rounded corners
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0), // Margin between cards
                elevation: 2,
                child: ListTile(
                  leading: Container(
                    decoration: BoxDecoration(
                      color: option.iconColor ?? Colors.deepPurple.shade100, // Background color
                      shape: BoxShape.circle, // Circular shape
                    ),
                    padding: const EdgeInsets.all(8.0), // Padding inside the circle
                    child: Icon(
                      isIOS ? option.cupertinoIcon : option.materialIcon,
                      color: option.iconColor ?? Colors.deepPurple, // Icon color
                      size: 28,
                    ),
                  ),
                  title: Text(
                    option.title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: option.subtitle != null
                      ? Text(
                          option.subtitle!,
                          style: const TextStyle(color: AppColors.grey),
                        )
                      : null,
                  trailing: Icon(
                    isIOS ? CupertinoIcons.chevron_forward : Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  onTap: () => option.onTap(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

