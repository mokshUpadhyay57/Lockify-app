import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lockify/screens/products/locked_messages/locked_message_screen.dart';


class LockedMessagesSummaryScreen extends StatefulWidget {
  const LockedMessagesSummaryScreen({super.key});

  @override
  State<LockedMessagesSummaryScreen> createState() =>
      _LockedMessagesSummaryScreenState();
}

class _LockedMessagesSummaryScreenState
    extends State<LockedMessagesSummaryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  List<Map<String, dynamic>> lockedMessages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (currentUserId != null) {
      _fetchLockedMessages();
    } else {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('User not authenticated. Please log in again.');
    }
  }

  Future<void> _fetchLockedMessages() async {
    try {
      // Fetch locked messages from Firestore
      final QuerySnapshot snapshot = await _firestore
          .collection('lockedMessages') // Replace with your Firestore collection name
          .where('createdBy', isEqualTo: currentUserId) // Filter by current user
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          lockedMessages = [];
          isLoading = false;
        });
        return;
      }

      final fetchedMessages = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'teaserText': doc['teaserText'] ?? 'No Teaser',
          'lockedContent': doc['lockedContent'] ?? 'No Content',
          'unlockPrice': doc['unlockPrice'] ?? 0,
          'createdAt': (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'expiryTime': doc['expiryTime'] ?? 'No Expiry',
          'uniqueCode': doc['uniqueCode'] ?? 'No Link',
        };
      }).toList();

      setState(() {
        lockedMessages = fetchedMessages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Failed to fetch locked messages. Error: $e');
    }
  }

  void _showErrorDialog(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locked Messages Summary', style: TextStyle(fontSize: 18),),
        backgroundColor: Colors.deepPurple,
        foregroundColor: AppColors.white,
        leading: const BackButton(
          color: AppColors.white,
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : lockedMessages.isEmpty
              ? const Center(
                  child: Text(
                    'No locked messages found.',
                    style: TextStyle(fontSize: 18, color: AppColors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: lockedMessages.length,
                  itemBuilder: (context, index) {
                    final message = lockedMessages[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          message['teaserText'],
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Expiry: ${message['expiryTime']}',
                              style: const TextStyle(color: AppColors.grey),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '₹${message['unlockPrice']}',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LockedMessageScreen(
                                documentId: message['id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

