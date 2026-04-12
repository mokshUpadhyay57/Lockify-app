import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoIcons
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'settings_options.dart';
 // Import the separated options
// Import for ImageFilter

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the platform is iOS
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return LockifyScaffold(
      title: 'Settings',
      appBarElevation: isIOS ? 0 : 4,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // Increased horizontal padding
        itemCount: settingsOptions.length,
        itemBuilder: (context, index) {
          final option = settingsOptions[index];
          return Card(
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
                size: 20,
                color: AppColors.grey,
              ),
              onTap: () => option.onTap(context),
            ),
          );
        },
      ),
    );
  }
}

