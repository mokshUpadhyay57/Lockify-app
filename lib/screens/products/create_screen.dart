import 'package:lockify/utils/snackbar.dart';
import 'package:lockify/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lockify/screens/products/chats/chat_detail_screen.dart';
import 'package:lockify/screens/products/channels/create_channel_screen.dart';
import 'package:lockify/screens/products/groups/create_group_screen.dart';
import 'package:lockify/screens/products/locked_messages/create_locked_message_screen.dart';
import 'package:lockify/screens/settings/verification/profile_verification_screen.dart';
import 'package:lockify/services/channel/channel_service.dart';
import 'package:lockify/utils/contacts.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';


class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  bool isVerified = false;
  bool _loadingVerification = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _fetchVerificationStatus();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    final fetchedContacts = await getContacts(context);
    if (!mounted) return;
    setState(() {
      contacts = fetchedContacts;
      filteredContacts = fetchedContacts;
    });
  }

  void _filterContacts(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      filteredContacts = contacts
          .where((contact) =>
              contact.displayName.toLowerCase().contains(lowerCaseQuery))
          .toList();
    });
  }

  Future<void> _fetchVerificationStatus() async {
    final userId = ChannelService().getCurrentUserId();
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!mounted) return;
    setState(() {
      final status = userDoc.data()?['isVerified'];
      isVerified = (status == "Verified" || status == true);
      _loadingVerification = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingVerification) {
      return LockifyScaffold(
        title: "Create",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        body: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // Top shimmer cards row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 8,
                          right: i == 2 ? 0 : 8,
                        ),
                        child: Shimmer.fromColors(
                          baseColor: AppColors.purple50,
                          highlightColor: AppColors.white,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.purple50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Shimmer search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Shimmer.fromColors(
                  baseColor: AppColors.grey200,
                  highlightColor: AppColors.white,
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Shimmer contact list
              Expanded(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Shimmer.fromColors(
                      baseColor: AppColors.grey100,
                      highlightColor: AppColors.white,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return LockifyScaffold(
      title: "Create",
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          // Main content (always rendered)
          Column(
            children: [
              // Top Cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopCard(
                      context,
                      color: AppColors.warningOrange,
                      icon: Icons.lock,
                      label: 'Locked\nMessage',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const CreateLockedMessageScreen()),
                      ),
                    ),
                    _buildTopCard(
                      context,
                      color: Colors.blue,
                      icon: Icons.campaign,
                      label: 'Channel\non Lockify',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateChannelScreen()),
                      ),
                    ),
                    _buildTopCard(
                      context,
                      color: AppColors.primaryPurple,
                      icon: Icons.group,
                      label: 'Group\non Lockify',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CreateGroupScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterContacts,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey100),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryPurple,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // List of Contacts
              Expanded(
                child: filteredContacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No contacts found.',
                          style: TextStyle(fontSize: 16, color: AppColors.grey),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = filteredContacts[index];
                          return _buildContactCard(contact);
                        },
                      ),
              ),
            ],
          ),

          // Blur and banner overlay if not verified
          if (!isVerified)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: AppColors.primaryPurple.withOpacity(0.18),
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 20, left: 24, right: 24),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.white, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Your account is not verified. Please complete verification to unlock all features.",
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileVerificationScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.white,
                              backgroundColor: AppColors.primaryPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "VERIFY NOW",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: AppColors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (contact.phones.isNotEmpty) {
              final phone = contact.phones.first.number;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(
                    recieverPhone: phone, // Pass the phone as is, normalization happens inside ChatDetailPage/Service
                    recieverName: contact.displayName,
                  ),
                ),
              );
            } else {
              AppSnackBar.error(context, 'No phone number available');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.purple50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      contact.displayName.isNotEmpty
                          ? contact.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name and phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.phones.isNotEmpty
                            ? contact.phones.first.number
                            : 'No phone number',
                        style: TextStyle(
                          color: AppColors.grey600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: onTap,
          child: _TopCard(color: color, icon: icon, label: label),
        ),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _TopCard({
    required this.color, 
    required this.icon, 
    required this.label
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.92), color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 28, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: 'Poppins',
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

