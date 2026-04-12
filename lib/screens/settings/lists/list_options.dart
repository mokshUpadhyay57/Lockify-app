import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lockify/screens/settings/lists/channel_screen.dart';
import 'package:lockify/screens/settings/lists/group_screen.dart';
import 'package:logger/logger.dart';
import 'package:lockify/screens/settings/lists/lock_messgages.dart';

// Initialize the logger
final Logger logger = Logger();

class ListOption {
  final String title;
  final String? subtitle; // Optional subtitle
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final void Function(BuildContext) onTap;
  final Color? iconColor;

  ListOption({
    required this.title,
    this.subtitle,
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.onTap,
    this.iconColor,
  });
}

// List of list options
final List<ListOption> listOptions = [
  ListOption(
    title: 'Locked Messages',
    subtitle: 'View all your locked messages',
    materialIcon: Icons.lock,
    cupertinoIcon: CupertinoIcons.lock,
    onTap: (BuildContext context) {
      _navigateTo(context, const LockedMessagesPage(), 'Locked Messages');
    },
  ),
  ListOption(
    title: 'Channel on Lockify',
    subtitle: 'View all your channels',
    materialIcon: Icons.campaign,
    cupertinoIcon: CupertinoIcons.add,
    onTap: (BuildContext context) {
      _navigateTo(context, const ChannelScreen(), 'Channel Summary on Lockify');
    },
  ),
  ListOption(
    title: 'Group on Lockify',
    subtitle: 'View all your Groups',
    materialIcon: Icons.group,
    cupertinoIcon: CupertinoIcons.group_solid,
    onTap: (BuildContext context) {
      _navigateTo(context, const GroupScreen(), 'Group Summary on Lockify');
    },
  ),
];

void _navigateTo(BuildContext context, Widget page, String pageName) {
  try {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    logger.i('Navigated to $pageName');
  } catch (e) {
    logger.e('Failed to navigate to $pageName: $e');
    _showErrorDialog(context, 'Failed to navigate to $pageName. Please try again.');
  }
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
