import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lockify/utils/app_logger.dart';

class LockedMessageViewerScreen extends StatefulWidget {
  final String documentId;
  const LockedMessageViewerScreen({super.key, required this.documentId});

  @override
  State<LockedMessageViewerScreen> createState() =>
      _LockedMessageViewerScreenState();
}

class _LockedMessageViewerScreenState extends State<LockedMessageViewerScreen> {
  // Memoize owner profile fetching
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

  Future<void> openFileFromUrl(String url) async {
    try {
      final dir = await getTemporaryDirectory();

      final fileName = url.split('/').last.split('?').first;
      final filePath = '${dir.path}/$fileName';

      // Download file
      await Dio().download(url, filePath);

      // Open with native app (media player / pdf viewer)
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        AppLogger.error("Open failed: ${result.message}");
      }
    } catch (e) {
      AppLogger.error("Error opening file", error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        title: const Text(
          'Unlocked Content',
          style: TextStyle(fontSize: 18, letterSpacing: 1.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 35,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('lockedMessages')
                .doc(widget.documentId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Message no longer exists.'));
          }

          var data = snapshot.data!.data()!;
          final createdBy = data['createdBy'] ?? '';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final formattedDate =
              createdAt != null
                  ? DateFormat('MMM d, yyyy').format(createdAt)
                  : 'Unknown Date';

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
                    // Content Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primaryPurple.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Creator Info
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

                            // Teaser
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

                            // Unlocked Content Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.onlineGreen.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.green200,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.lock_open,
                                        color: AppColors.onlineGreen,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "UNLOCKED MESSAGE",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onlineGreen,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    data['lockedContent'] ?? 'No content',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Image
                                  if (data['imageUrl'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          data['imageUrl'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                  // Video
                                  if (data['videoUrl'] != null)
                                    InkWell(
                                      onTap:
                                          () =>
                                              openFileFromUrl(data['videoUrl']),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.purple50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(
                                              Icons.play_circle_fill,
                                              color: AppColors.primaryPurple,
                                              size: 30,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              "Play Video",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryPurple,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Document
                                  if (data['documentUrl'] != null)
                                    InkWell(
                                      onTap:
                                          () => openFileFromUrl(
                                            data['documentUrl'],
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(
                                              Icons.insert_drive_file,
                                              color: Colors.blue,
                                              size: 30,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              "Download Document",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
}
