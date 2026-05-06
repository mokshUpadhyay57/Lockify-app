import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lockify/utils/colors.dart';

class WithdrawalHistoryScreen extends StatelessWidget {
  const WithdrawalHistoryScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _withdrawalsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('withdrawals')
        .orderBy('requestedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _walletStream(String uid) {
    return FirebaseFirestore.instance
        .collection('wallets')
        .doc(uid)
        .snapshots();
  }

  double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'success':
      case 'completed':
        return AppColors.onlineGreen;
      case 'rejected':
      case 'failed':
      case 'cancelled':
        return AppColors.errorRed;
      default:
        return AppColors.warningOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Withdrawal Requests'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please login to view withdrawals.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _walletStream(user.uid),
              builder: (context, walletSnapshot) {
                final walletData = walletSnapshot.data?.data();
                final availableBalance = _readAmount(
                  walletData?['availableBalance'],
                );
                final pendingBalance = _readAmount(
                  walletData?['pendingBalance'],
                );

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _withdrawalsStream(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final withdrawals = snapshot.data?.docs ?? [];
                    final totalRequested = withdrawals.fold<double>(
                      0,
                      (runningTotal, doc) =>
                          runningTotal + _readAmount(doc.data()['amount']),
                    );
                    final pendingRequests = withdrawals
                        .where(
                          (doc) =>
                              (doc.data()['status'] as String? ?? '')
                                  .toLowerCase() ==
                              'pending',
                        )
                        .length;

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Withdrawal Overview',
                                style: TextStyle(
                                  color: AppColors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${_formatAmount(totalRequested)}',
                                style: const TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontSize: 30,
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
                                      AppColors.green50,
                                      AppColors.green700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _summaryItem(
                                      'Pending',
                                      '$pendingRequests req',
                                      AppColors.purple50,
                                      AppColors.purple700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _summaryItem(
                                      'On hold',
                                      '₹${_formatAmount(pendingBalance)}',
                                      AppColors.warningOrange.withOpacity(0.12),
                                      AppColors.warningOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (withdrawals.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.history_toggle_off,
                                    size: 64,
                                    color: AppColors.grey400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No withdrawal requests yet',
                                    style: TextStyle(
                                      color: AppColors.grey600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: withdrawals.length,
                              itemBuilder: (context, index) {
                                return _withdrawalTile(withdrawals[index].data());
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _summaryItem(
    String label,
    String value,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _withdrawalTile(Map<String, dynamic> data) {
    final amount = _readAmount(data['amount']);
    final status = data['status'] as String? ?? 'pending';
    final requestedAt = (data['requestedAt'] as Timestamp?)?.toDate();
    final date = requestedAt == null
        ? 'Date unavailable'
        : DateFormat('MMM d, yyyy - h:mm a').format(requestedAt);

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
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.purple50,
          child: const Icon(
            Icons.account_balance,
            color: AppColors.primaryPurple,
          ),
        ),
        title: Text(
          '₹${_formatAmount(amount)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Requested on $date',
            style: const TextStyle(height: 1.35),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: _statusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
