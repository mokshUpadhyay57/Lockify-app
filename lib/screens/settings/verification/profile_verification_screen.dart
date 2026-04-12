import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'upload_screen.dart';
 // Import the UploadScreen

class ProfileVerificationScreen extends StatefulWidget {
  const ProfileVerificationScreen({super.key});

  @override
  State<ProfileVerificationScreen> createState() => _ProfileVerificationScreenState();
}

class _ProfileVerificationScreenState extends State<ProfileVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return LockifyScaffold(
      title: 'Profile Verification',
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            child: ListTile(
              leading: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8.0),
                child: const Icon(Icons.upload_file, color: Colors.deepPurple, size: 28),
              ),
              title: const Text(
                'Aadhar Verify',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: AppColors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadScreen(type: 'Aadhar'),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            child: ListTile(
              leading: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8.0),
                child: const Icon(Icons.upload_file, color: Colors.deepPurple, size: 28),
              ),
              title: const Text(
                'PAN Verify',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: AppColors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadScreen(type: 'PAN'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

