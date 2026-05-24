import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lockify/screens/settings/lists/group_summary_screen.dart';


class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups', style: TextStyle(fontSize: 18)),
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
            subtitle: 'List of all created groups',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GroupSummaryScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.group_outlined,
            title: 'Joined',
            subtitle: 'List of all joined groups',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GroupSummaryScreen(createdOnly: false),
                ),
              );
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

}

