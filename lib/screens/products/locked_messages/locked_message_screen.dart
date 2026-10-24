import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lockify/utils/snackbar.dart';
import 'package:lockify/screens/products/locked_messages/create_locked_message_screen.dart';
import 'package:lockify/screens/products/locked_messages/edit_locked_message_screen.dart';

class LockedMessageScreen extends StatefulWidget {
  final String documentId;
  const LockedMessageScreen({super.key, required this.documentId});

  @override
  State<LockedMessageScreen> createState() => _LockedMessageScreenState();
}

class _LockedMessageScreenState extends State<LockedMessageScreen> {
  final String baseUrl = 'https://lockify.co.in/';

  // Optimization: Cache owner data to avoid re-fetching on every message update
  Future<DocumentSnapshot<Map<String, dynamic>>>? _ownerFuture;
  String? _lastCreatedBy;

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchUserByUID(
    String uid,
  ) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: uid)
            .get();
    if (querySnapshot.docs.isEmpty) throw Exception('User not found');
    return querySnapshot.docs.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        title: const Text(
          'Locked Message',
          style: TextStyle(fontSize: 18, letterSpacing: 1.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 35,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateLockedMessageScreen(),
                  ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditLockedMessageScreen(
                          documentId: widget.documentId,
                        ),
                  ),
                ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('lockedMessages')
                .doc(widget.documentId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text('No data found'));

          var data = snapshot.data!.data()!;
          final uniqueCode = data['uniqueCode'] ?? '';
          final shareLink = uniqueCode.isNotEmpty ? '$baseUrl$uniqueCode' : '';
          final createdBy = data['createdBy'] ?? '';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final formattedDate =
              createdAt != null
                  ? DateFormat('MMM d, yyyy').format(createdAt)
                  : 'Unknown Date';

          // Optimization: Only update the future if the owner has changed
          if (_ownerFuture == null || _lastCreatedBy != createdBy) {
            _lastCreatedBy = createdBy;
            _ownerFuture = fetchUserByUID(createdBy);
          }

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _ownerFuture,
            builder: (context, userSnapshot) {
              String ownerName = 'Loading...';
              String username = '...';
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData = userSnapshot.data!.data()!;
                var email = userData['email'] ?? 'Unknown User';

                ownerName = email.split('@').first;
                username = email.split('@').first;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Preview Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primaryPurple,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ownerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "@$username",
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            const Text(
                              "TEASER",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPurple,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['teaserText'] ?? 'No teaser',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "LOCKED CONTENT",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.errorRed,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['lockedContent'] ?? 'No content',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            if (data['imageUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['imageUrl'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (data['videoUrl'] != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.videocam,
                                      color: AppColors.primaryPurple,
                                    ),
                                    SizedBox(width: 10),
                                    Text("Video Attached"),
                                  ],
                                ),
                              ),
                            if (data['documentUrl'] != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.insert_drive_file,
                                      color: AppColors.primaryPurple,
                                    ),
                                    SizedBox(width: 10),
                                    Text("Document Attached"),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Admin Panel Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              "ADMIN PANEL",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.pinkAccent,
                                    Colors.deepPurpleAccent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                shareLink,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: AppColors.primaryPurple,
                                  ),
                                  onPressed:
                                      () => SharePlus.instance.share(
                                        ShareParams(
                                          text: shareLink,
                                          subject:
                                              "Check out this locked message!",
                                        ),
                                      ),
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    color: AppColors.primaryPurple,
                                  ),
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: shareLink),
                                    );
                                    if (context.mounted)
                                      AppSnackBar.success(
                                        context,
                                        'Link copied!',
                                      );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _infoRow(
                              'Message Price',
                              '₹${data['unlockPrice'] ?? '0'}',
                            ),
                            _infoRow(
                              'Purchased Count',
                              '${data['purchasedCount'] ?? 0}',
                            ),
                            _infoRow(
                              'Expiry',
                              data['expiryTime'] ?? 'No expiry',
                            ),
                            _infoRow(
                              'Public after expiry',
                              data['isPublic'] == true ? 'Yes' : 'No',
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                foregroundColor: AppColors.white,
                              ),
                              onPressed: () {},
                              child: const Text('VIEW SALES DASHBOARD'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
