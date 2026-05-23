import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lockify/screens/settings/lists/channel_screen.dart';
import 'package:lockify/screens/settings/lists/group_screen.dart';
import 'package:logger/logger.dart';
import 'package:lockify/screens/settings/lists/locked_messages.dart';

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
    subtitle: 'Manage your locked messages',
    materialIcon: Icons.lock,
    cupertinoIcon: CupertinoIcons.lock,
    onTap: (BuildContext context) {
      _navigateTo(context, const LockedMessagesPage(), 'Locked Messages');
    },
  ),
  ListOption(
    title: 'Channels',
    subtitle: 'Manage your channels',
    materialIcon: Icons.campaign,
    cupertinoIcon: CupertinoIcons.chat_bubble_2,
    onTap: (BuildContext context) {
      _navigateTo(context, const ChannelScreen(), 'Channels');
    },
  ),
  ListOption(
    title: 'Groups',
    subtitle: 'Manage your groups',
    materialIcon: Icons.group,
    cupertinoIcon: CupertinoIcons.group_solid,
    onTap: (BuildContext context) {
      _navigateTo(context, const GroupScreen(), 'Groups');
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
