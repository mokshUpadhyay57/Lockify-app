import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lockify/screens/settings/lists/channel_summary_screen.dart';


class ChannelScreen extends StatelessWidget {
  const ChannelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels', style: TextStyle(fontSize: 18)),
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        children: [
          _buildListTile(
            context,
            icon: Icons.lock_open_outlined,
            title: 'Created',
            subtitle: 'List of all created Channels',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChannelSummaryScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.lock_outline,
            title: 'Purchased',
            subtitle: 'List of all purchased locked messages',
            onTap: () {
              // Navigate to the Purchased Locked Messages screen (if implemented)
              _showComingSoonDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Coming Soon"),
        content: const Text("This feature is under development."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

