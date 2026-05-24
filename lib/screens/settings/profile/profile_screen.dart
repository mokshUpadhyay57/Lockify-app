import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/components/widgets/profile_header.dart';
import 'package:lockify/screens/products/channels/channel_chat_screen.dart';
import 'package:lockify/screens/settings/setting/profile_update_screen.dart';
import 'package:lockify/services/auth/auth_service.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception("User not authenticated");
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      setState(() {
        userData = userDoc.data();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPublicChannelsStream() {
    return _firestore.collection('channels').where('groupType', isEqualTo: 'Public').snapshots();
  }

  Widget buildChannelList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getPublicChannelsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No public channels found.'));
        }
        final channels = snapshot.data!.docs;
        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channelDoc = channels[index];
            final channel = channelDoc.data();
            final channelName = channel['name']?.toString() ?? 'Channel';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChannelDetailPage(
                        channelId: channel['channelId']?.toString() ?? channelDoc.id,
                        channelName: channelName,
                        channelDesc: channel['description']?.toString() ?? '',
                        channelImage: channel['imageUrl']?.toString() ?? '',
                        isPaid: channel['isPaid'] == true || channel['isPaid'] == 'true',
                        participants: channel['participantUids'] ?? [],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.17),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                            channelName.isNotEmpty ? channelName[0].toUpperCase() : '?',
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
                      // Channel info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channelName,
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
                              channel['description'] ?? 'No description',
                              style: TextStyle(color: AppColors.grey600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, color: AppColors.purple200, size: 18),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LockifyScaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return LockifyScaffold(body: Center(child: Text('Error: $error')));
    }
    if (userData == null) {
      return const LockifyScaffold(body: Center(child: Text('No user data found.')));
    }

    final name = '${userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}'.trim();
    final username = userData!['username'] ?? 'Unknown';
    final isOnline = userData!['isOnline'] ?? false;

    return LockifyScaffold(
      backgroundColor: AppColors.white,
      appBarElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_sharp, color: AppColors.white, size: 28),
          tooltip: 'Edit Profile',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdateProfileScreen()));
          },
        ),
        IconButton(
          icon: const Icon(Icons.ios_share, color: AppColors.white),
          tooltip: 'Share Profile',
          onPressed: () {
            final shareText =
                'Check out my profile on Lockify!\n'
                'Name: ${name.isNotEmpty ? name : 'No Name'}\n'
                'Username: $username';

            SharePlus.instance.share(
              ShareParams(
                text: shareText,
                subject: 'Lockify Profile',
                title: "See me on Lockify",
                sharePositionOrigin: Rect.fromLTWH(0, 0, 0, 0),
              ),
            );
          },
        ),
        SizedBox(width: 10),
      ],
      body: SafeArea(
        child: Column(
          children: [
            ProfileHeader(name: name.isNotEmpty ? name : 'No Name', username: username, isOnline: isOnline),
            const Divider(color: AppColors.primaryPurple, height: 1, thickness: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 20),
            Expanded(child: buildChannelList()),
          ],
        ),
      ),
    );
  }
}

