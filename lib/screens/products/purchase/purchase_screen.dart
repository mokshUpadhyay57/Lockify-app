import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lockify/services/purchase_service.dart';
import 'package:lockify/screens/products/locked_messages/locked_message_viewer_screen.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final PurchaseService _purchaseService = PurchaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "To unlock new messages, use the web link provided by the creator. Your unlocked content will appear here.",
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _purchaseService.streamMyPurchases(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.grey400),
                        const SizedBox(height: 16),
                        Text(
                          'No purchases yet',
                          style: TextStyle(color: AppColors.grey600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final purchases = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final purchaseData = purchases[index].data() as Map<String, dynamic>;
                    final lockedMessageId = purchaseData['lockedMessageId'] ?? '';
                    final pricePaid = purchaseData['pricePaid'] ?? 0;
                    final purchasedAt = (purchaseData['purchasedAt'] as Timestamp?)?.toDate();
                    final dateStr = purchasedAt != null ? DateFormat('MMM d, yyyy').format(purchasedAt) : '';

                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: _purchaseService.getLockedMessage(lockedMessageId),
                      builder: (context, msgSnapshot) {
                        if (!msgSnapshot.hasData) {
                          return const Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(title: Text('Loading...')),
                          );
                        }

                        if (!msgSnapshot.data!.exists) {
                          return const Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(Icons.error_outline, color: AppColors.errorRed),
                              title: Text('Content unavailable', style: TextStyle(color: AppColors.grey)),
                            ),
                          );
                        }

                        final msgData = msgSnapshot.data!.data()!;
                        final teaserText = msgData['teaserText'] ?? 'No teaser';


                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LockedMessageViewerScreen(documentId: lockedMessageId),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.green100,
                                child: const Icon(Icons.lock_open, color: AppColors.onlineGreen),
                              ),
                              title: Text(
                                teaserText,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('₹$pricePaid • Unlocked $dateStr'),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

