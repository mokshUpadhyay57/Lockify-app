import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lockify/utils/colors.dart';

class ExpenditureScren extends StatelessWidget {
  const ExpenditureScren({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _transactionStream(String uid) {
    return FirebaseFirestore.instance
        .collection('wallet_transactions')
        .where('userId', isEqualTo: uid)
        .limit(50)
        .snapshots();
  }

  double _readAmount(Map<String, dynamic> data) {
    final value = data['amount'];
    if (value is num) return value.toDouble();
    return 0;
  }

  bool _isDebit(Map<String, dynamic> data) {
    final type = (data['type'] as String? ?? '').toUpperCase();
    final category = (data['category'] as String? ?? '').toUpperCase();
    final sourceType = (data['sourceType'] as String? ?? '').toUpperCase();
    return type == 'DEBIT' ||
        category.contains('WITHDRAW') ||
        category.contains('EXPENSE') ||
        category.contains('FEE') ||
        sourceType.contains('WITHDRAW');
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Expenditure'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please login to view expenditures.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _transactionStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final transactions = (snapshot.data?.docs ?? [])
                    .where((doc) => _isDebit(doc.data()))
                    .toList()
                  ..sort((a, b) {
                    final aDate =
                        (a.data()['createdAt'] as Timestamp?)?.toDate();
                    final bDate =
                        (b.data()['createdAt'] as Timestamp?)?.toDate();
                    if (aDate == null) return 1;
                    if (bDate == null) return -1;
                    return bDate.compareTo(aDate);
                  });

                final totalSpent = transactions.fold<double>(
                  0,
                  (runningTotal, doc) =>
                      runningTotal + _readAmount(doc.data()),
                );

                return Column(
                  children: [
                    Container(
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.red50,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.trending_down,
                              color: AppColors.errorRed,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Expenditure',
                                  style: TextStyle(
                                    color: AppColors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${_formatAmount(totalSpent)}',
                                  style: const TextStyle(
                                    color: AppColors.errorRed,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _metricCard(
                            '${transactions.length}',
                            'Entries',
                          ),
                        ],
                      ),
                    ),
                    if (transactions.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: AppColors.grey400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No expenditures yet',
                                style: TextStyle(
                                  color: AppColors.grey600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Withdrawal payouts and other debits will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.grey600),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _transactionTile(transactions[index].data());
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _metricCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.red700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(Map<String, dynamic> data) {
    final amount = _readAmount(data);
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final date = createdAt == null
        ? 'Date unavailable'
        : DateFormat('MMM d, yyyy - h:mm a').format(createdAt);
    final category = data['category'] as String? ?? 'EXPENDITURE';
    final status = data['status'] as String? ?? 'PENDING';
    final sourceId = data['sourceId'] as String? ?? '';

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
          backgroundColor: AppColors.red50,
          child: const Icon(Icons.arrow_upward, color: AppColors.errorRed),
        ),
        title: Text(
          '-₹${_formatAmount(amount)}',
          style: const TextStyle(
            color: AppColors.errorRed,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              category.replaceAll('_', ' '),
              date,
              if (sourceId.isNotEmpty) 'Ref: $sourceId',
            ].join('\n'),
            style: const TextStyle(height: 1.35),
          ),
        ),
        trailing: Text(
          status,
          style: const TextStyle(
            color: AppColors.red700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
