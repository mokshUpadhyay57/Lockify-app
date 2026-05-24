import 'package:lockify/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lockify/utils/snackbar.dart';

class AccountPrivacyPage extends StatefulWidget {
  const AccountPrivacyPage({super.key});

  @override
  State<AccountPrivacyPage> createState() => _AccountPrivacyPageState();
}

class _AccountPrivacyPageState extends State<AccountPrivacyPage> {
  bool isAccountPublic = true;
  bool isVisibleInContacts = true;
  bool isLoading = true;
  bool isSaving = false;
  String phoneNumber = "";
  String? emailId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user is logged in.");

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};

      if (!mounted) return;
      setState(() {
        isAccountPublic = data['isAccountPublic'] as bool? ?? true;
        isVisibleInContacts = data['isVisibleInContacts'] as bool? ?? true;
        phoneNumber = (data['phone'] ?? user.phoneNumber ?? '').toString();
        emailId = (data['email'] ?? user.email) as String?;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      AppSnackBar.error(context, "Unable to load privacy settings: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user is logged in.");

      setState(() => isSaving = true);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'isAccountPublic': isAccountPublic,
          'isVisibleInContacts': isVisibleInContacts,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      AppSnackBar.success(context, "Settings saved successfully");
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, "Unable to save settings: $e");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account & Privacy", style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: isSaving ? null : _saveSettings,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PrivacySwitchTile(
                  title: "Make your account public",
                  subtitle: "By enabling this, you will come up in search results",
                  value: isAccountPublic,
                  onChanged: (value) => setState(() => isAccountPublic = value),
                ),
                const SizedBox(height: 20),
                PrivacySwitchTile(
                  title: "Show up in contact lists",
                  subtitle:
                      "By enabling this, you will come up in contact list of your friends who have your contact number and are on Lockify",
                  value: isVisibleInContacts,
                  onChanged: (value) => setState(() => isVisibleInContacts = value),
                ),
                const SizedBox(height: 20),
                const Divider(
                  thickness: 1,
                  color: AppColors.grey,
                  indent: 10,
                  endIndent: 10,
                ),
                const SizedBox(height: 10),
                ContactInfoTile(
                  icon: Icons.phone,
                  label: phoneNumber.isEmpty ? "No phone number present" : phoneNumber,
                  isLink: false,
                ),
                ContactInfoTile(
                  icon: Icons.email,
                  label: emailId ?? "No email ID present",
                  isLink: false,
                ),
              ],
            ),
    );
  }
}

class PrivacySwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PrivacySwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class ContactInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLink;
  final VoidCallback? onTap;

  const ContactInfoTile({
    super.key,
    required this.icon,
    required this.label,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(
        label,
        style: TextStyle(
          color: isLink ? Colors.blue : AppColors.black,
          decoration: isLink ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
      onTap: isLink ? onTap : null,
    );
  }
}

