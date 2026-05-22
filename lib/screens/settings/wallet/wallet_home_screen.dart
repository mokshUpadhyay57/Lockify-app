import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/services/wallet_service.dart';
import 'package:lockify/utils/colors.dart';

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {
  final WalletService _walletService = WalletService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const LockifyScaffold(
        title: "Wallet",
        body: Center(child: Text("Please login to view your wallet.")),
      );
    }

    return LockifyScaffold(
      title: "Wallet",
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                "Recent Transactions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black87,
                ),
              ),
            ),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _walletService.getWalletStream(),
      builder: (context, snapshot) {
        final walletData = snapshot.data?.data();
        final availableBalance = _walletService.readAmount(walletData?['availableBalance']);
        final pendingBalance = _walletService.readAmount(walletData?['pendingBalance']);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.purple900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Balance",
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "₹${_walletService.formatAmount(availableBalance)}",
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildBalanceInfo("Available", availableBalance),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  _buildBalanceInfo("Pending", pendingBalance),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceInfo(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "₹${_walletService.formatAmount(amount)}",
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _walletService.getTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final transactions = snapshot.data?.docs ?? [];
        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text("No transactions found.", style: TextStyle(color: AppColors.black54)),
            ),
          );
        }

        // Sort transactions by createdAt descending in memory
        final sortedTransactions = transactions.toList()
          ..sort((a, b) {
            final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bTime.compareTo(aTime);
          });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sortedTransactions.length > 20 ? 20 : sortedTransactions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = sortedTransactions[index].data();
            return _buildTransactionTile(data);
          },
        );
      },
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> data) {
    final isDebit = _walletService.isDebit(data);
    final amount = _walletService.readAmount(data['amount']);
    final title = data['title'] ?? (isDebit ? "Expenditure" : "Earning");
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt) : 'N/A';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDebit ? AppColors.errorRed.withValues(alpha: 0.1) : AppColors.onlineGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDebit ? Icons.arrow_outward : Icons.south_west,
          color: isDebit ? AppColors.errorRed : AppColors.onlineGreen,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        dateStr,
        style: const TextStyle(
          color: AppColors.black54,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        "${isDebit ? '-' : '+'}₹${_walletService.formatAmount(amount)}",
        style: TextStyle(
          color: isDebit ? AppColors.errorRed : AppColors.onlineGreen,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
