import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoIcons
import 'package:logger/logger.dart';

// All Settings Options
import 'package:lockify/screens/settings/setting/account_privacy.dart';
import 'package:lockify/screens/settings/setting/faq_screen.dart';
import 'package:lockify/screens/settings/setting/profile_intro.dart';
import 'package:lockify/screens/settings/setting/profile_update_screen.dart';
import 'package:lockify/screens/settings/setting/signout.dart';
// import 'package:lockify/screens/settings/setting/upload_invoice.dart';
import 'package:lockify/screens/settings/setting/whatsapp_help_screen.dart';
import 'package:lockify/screens/settings/lists/locked_messages.dart';

// Initialize the logger
final Logger logger = Logger();

class SettingsOption {
  final String title;
  final String? subtitle; // Add subtitle property
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final void Function(BuildContext) onTap;
  final Color? iconColor;

  SettingsOption({
    required this.title,
    this.subtitle, // Optional subtitle
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.onTap,
    this.iconColor,
  });
}

// List of settings options
final List<SettingsOption> settingsOptions = [
  SettingsOption(
    title: 'Profile',
    subtitle: 'View and edit your profile',
    materialIcon: Icons.person,
    cupertinoIcon: CupertinoIcons.person,
    onTap: (BuildContext context) {
       Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UpdateProfileScreen()),
      );
      logger.i('Navigate to Profile');
    },
  ),
  SettingsOption(
    title: 'Lock Direct Message',
    subtitle: 'Secure your messages',
    materialIcon: Icons.lock,
    cupertinoIcon: CupertinoIcons.lock,
    onTap: (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LockedMessagesPage()),
      );
      logger.i('Navigate to Lock Direct Message');
    },
  ),
  SettingsOption(
    title: 'Add Profile Intro',
    subtitle: 'Add a short introduction',
    materialIcon: Icons.info,
    cupertinoIcon: CupertinoIcons.info,
    onTap: (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddProfileIntroPage()),
      );
      logger.i('Add Profile Intro');
    },
  ),
  SettingsOption(
    title: 'Account & Privacy',
    subtitle: 'Manage your account settings',
    materialIcon: Icons.privacy_tip,
    cupertinoIcon: CupertinoIcons.lock_shield,
    onTap: (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountPrivacyPage()),
      );
      logger.i('Navigate to Account & Privacy');
    },
  ),
  SettingsOption(
    title: 'FAQs',
    subtitle: 'Frequently asked questions',
    materialIcon: Icons.help,
    cupertinoIcon: CupertinoIcons.question_circle,
    onTap: (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FAQsPage()),
      );
      logger.i('Navigate to FAQs');
    },
  ),
  // SettingsOption(
  //   title: 'Upload Invoice Detail',
  //   subtitle: 'Upload your invoices',
  //   materialIcon: Icons.file_upload,
  //   cupertinoIcon: CupertinoIcons.cloud_upload_fill,
  //   onTap: (BuildContext context) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => UploadInvoicePage()),
  //     );
  //     logger.i('Upload Invoice Detail');
  //   },
  // ),
  SettingsOption(
    title: 'Need Help (WhatsApp)',
    subtitle: 'Contact us via WhatsApp',
    materialIcon: Icons.chat_bubble,
    cupertinoIcon: CupertinoIcons.chat_bubble,
    onTap: (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WhatsAppHelpScreen()),
      );
      logger.i('Navigate to WhatsApp Help');
    },
  ),
  SettingsOption(
    title: 'Sign Out',
    subtitle: 'Log out of your account',
    materialIcon: Icons.logout_outlined,
    cupertinoIcon: CupertinoIcons.square_arrow_right_fill,
    onTap: (BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignOutPage()),
      );
      logger.i('Sign Out');
      logger.w('User signed out');
    },
  ),
];
