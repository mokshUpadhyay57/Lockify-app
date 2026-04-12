import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lockify/screens/products/locked_messages/locked_message_screen.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';


class LockedMessageListScreen extends StatelessWidget {
  const LockedMessageListScreen({super.key});

  // Function to stream locked messages (Optimized with limit)
  Stream<List<QueryDocumentSnapshot>> streamMessages(String userId) {
    return FirebaseFirestore.instance
        .collection('lockedMessages')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20) // Optimization: Limit to latest 20 messages
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return LockifyScaffold(
      showAppBar: false,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = authSnapshot.data;

          if (currentUser == null) {
            return const Center(child: Text('No user logged in.'));
          }

          // Stream locked messages for real-time updates
          return StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: streamMessages(currentUser.uid),
            builder: (context, messagesSnapshot) {
              if (messagesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (messagesSnapshot.hasError) {
                return Center(child: Text('Error: ${messagesSnapshot.error}'));
              }

              if (!messagesSnapshot.hasData || messagesSnapshot.data!.isEmpty) {
                return const Center(child: Text('No locked messages found.'));
              }

              final messages = messagesSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var data = messages[index].data() as Map<String, dynamic>;
                  var price = data['unlockPrice'] ?? 0;
                  var teaserText = data['teaserText'] ?? 'No teaser text';
                  var timestamp = data['createdAt'] as Timestamp?;
                  var formattedDate = timestamp != null
                      ? DateFormat('MMM d, yyyy hh:mm a').format(timestamp.toDate())
                      : 'Unknown Date';


                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LockedMessageScreen(
                            documentId: messages[index].id,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.grey.withAlpha(90),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.lock, color: AppColors.primaryPurple),
                        title: Text(
                          teaserText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('₹$price • $formattedDate'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

