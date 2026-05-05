import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lockify/utils/colors.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  double _readAmount(Map<String, dynamic>? data, String key) {
    final value = data?[key];
    if (value is num) return value.toDouble();
    return 0;
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _walletStream(String uid) {
    return FirebaseFirestore.instance
        .collection('wallets')
        .doc(uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _earningTransactionsStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('wallet_transactions')
        .where('userId', isEqualTo: uid)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
      ),
      body:
          user == null
              ? const Center(child: Text('Please login to view earnings.'))
              : Column(
                children: [
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _walletStream(user.uid),
                    builder: (context, snapshot) {
                      final walletData = snapshot.data?.data();
                      final totalEarned = _readAmount(
                        walletData,
                        'totalEarned',
                      );
                      final availableBalance = _readAmount(
                        walletData,
                        'availableBalance',
                      );
                      final pendingBalance = _readAmount(
                        walletData,
                        'pendingBalance',
                      );

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Earnings',
                              style: TextStyle(
                                color: AppColors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${_formatAmount(totalEarned)}',
                              style: const TextStyle(
                                color: AppColors.onlineGreen,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _summaryItem(
                                    'Available',
                                    '₹${_formatAmount(availableBalance)}',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _summaryItem(
                                    'Pending',
                                    '₹${_formatAmount(pendingBalance)}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _earningTransactionsStream(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final transactions =
                            (snapshot.data?.docs ?? []).where((doc) {
                                final data = doc.data();
                                return data['type'] == 'CREDIT' &&
                                    data['category'] == 'ORDER_EARNING';
                              }).toList()
                              ..sort((a, b) {
                                final aDate =
                                    (a.data()['createdAt'] as Timestamp?)
                                        ?.toDate();
                                final bDate =
                                    (b.data()['createdAt'] as Timestamp?)
                                        ?.toDate();
                                if (aDate == null) return 1;
                                if (bDate == null) return -1;
                                return bDate.compareTo(aDate);
                              });

                        if (transactions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.trending_up,
                                  size: 64,
                                  color: AppColors.grey400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No earnings yet',
                                  style: TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final data = transactions[index].data();
                            return _transactionTile(data);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.green700,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(Map<String, dynamic> data) {
    final amount =
        data['amount'] is num ? (data['amount'] as num).toDouble() : 0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final date =
        createdAt == null
            ? 'Date unavailable'
            : DateFormat('MMM d, yyyy - h:mm a').format(createdAt);
    final sourceId =
        data['sourceId'] as String? ?? data['orderId'] as String? ?? '';
    final buyerPhone = data['buyerPhone'] as String? ?? '';
    final status = data['status'] as String? ?? 'SUCCESS';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.green100,
          child: const Icon(Icons.arrow_downward, color: AppColors.onlineGreen),
        ),
        title: Text(
          '₹${_formatAmount(amount)}',
          style: const TextStyle(
            color: AppColors.onlineGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              date,
              if (buyerPhone.isNotEmpty) 'Buyer: $buyerPhone',
              if (sourceId.isNotEmpty) 'Order: $sourceId',
            ].join('\n'),
            style: const TextStyle(height: 1.35),
          ),
        ),
        trailing: Text(
          status,
          style: const TextStyle(
            color: AppColors.green700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
