import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';

import 'package:lockify/screens/settings/earning/add_bank_detail_screen.dart';
import 'package:lockify/screens/settings/earning/earnings_screen.dart';
import 'package:lockify/screens/settings/earning/expenditure_scren.dart';
import 'package:lockify/screens/settings/earning/withdrawal_history_screen.dart';

// --- Modularized Dialogs ---
Future<void> showInfoDialog(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.white,
          title: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primaryPurple,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16, color: AppColors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
  );
}

Future<void> showLimitDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.white,
          title: Row(
            children: const [
              Icon(Icons.lock_clock, color: AppColors.primaryPurple, size: 28),
              SizedBox(width: 10),
              Text(
                "Withdrawal Limit Reached",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "You have reached the maximum of 3 withdrawals in 24 hours. Please wait 1 week before making another withdrawal.",
            style: TextStyle(fontSize: 16, color: AppColors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
  );
}

Future<void> showSuccessDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.white,
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.onlineGreen, size: 28),
              SizedBox(width: 10),
              Text(
                "Withdrawal Successful",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Your withdrawal request has been submitted.",
            style: TextStyle(fontSize: 16, color: AppColors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
  );
}

// --- Modularized Withdrawal Logic ---
Future<bool> canWithdraw(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final now = DateTime.now();
  final withdrawalsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('withdrawals');

  // Only fetch last 7 days, limit to 5 for efficiency
  final weekAgo = now.subtract(const Duration(days: 7));
  final snapshot =
      await withdrawalsRef
          .where('requestedAt', isGreaterThan: weekAgo)
          .orderBy('requestedAt', descending: true)
          .limit(5)
          .get();

  final withdrawals =
      snapshot.docs
          .map((doc) => (doc['requestedAt'] as Timestamp).toDate())
          .toList();

  final dayAgo = now.subtract(const Duration(hours: 24));
  final last24h = withdrawals.where((dt) => dt.isAfter(dayAgo)).toList();

  if (last24h.length >= 3) {
    final lastWithdrawal = withdrawals.isNotEmpty ? withdrawals.first : null;
    if (lastWithdrawal != null && now.difference(lastWithdrawal).inDays < 7) {
      await showLimitDialog(context);
      return false;
    }
  }
  return true;
}

Future<void> handleWithdraw(BuildContext context, double balance) async {
  if (balance < 100) {
    await showInfoDialog(
      context,
      "Minimum Withdrawal",
      "You need at least ₹100 to withdraw.",
    );
    return;
  }
  if (await canWithdraw(context)) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();

    final withdrawalData = {
      'amount': balance,
      'status': 'pending',
      'requestedAt': now,
      'uid': user.uid,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('withdrawals')
        .add(withdrawalData);

    await FirebaseFirestore.instance
        .collection('withdrawals')
        .add(withdrawalData);

    await showSuccessDialog(context);
  }
}

class EarningHomeScreen extends StatefulWidget {
  const EarningHomeScreen({super.key});

  @override
  State<EarningHomeScreen> createState() => _EarningHomeScreenState();
}

class _EarningHomeScreenState extends State<EarningHomeScreen> {
  late Future<String> _isVerifiedFuture;

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

  Future<String> fetchUserVerifiedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "false";
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return doc.data()?['isVerified'] ?? "Not Verified";
  }

  void _refreshStatus() {
    setState(() {
      _isVerifiedFuture = fetchUserVerifiedStatus();
    });
  }

  @override
  void initState() {
    super.initState();
    _isVerifiedFuture = fetchUserVerifiedStatus();
  }

  @override
  Widget build(BuildContext context) {
    return LockifyScaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      title: "Earnings",
      appBarElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.white, size: 26),
          onPressed: _refreshStatus,
          tooltip: "Refresh status",
        ),
      ],
      body: FutureBuilder<String>(
        future: _isVerifiedFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final isVerified = snapshot.data?.toLowerCase() == "verified";
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: isVerified ? AppColors.green50 : AppColors.red50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  margin: const EdgeInsets.only(bottom: 28),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isVerified ? AppColors.green50 : AppColors.red50,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isVerified
                                  ? AppColors.onlineGreen.withOpacity(0.13)
                                  : AppColors.errorRed.withOpacity(0.13),
                          blurRadius: 22,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.04),
                          blurRadius: 5,
                          spreadRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                isVerified
                                    ? AppColors.green100
                                    : AppColors.red100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            isVerified ? Icons.verified : Icons.error_outline,
                            color:
                                isVerified
                                    ? AppColors.onlineGreen
                                    : AppColors.errorRed,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVerified
                                    ? "Profile verified"
                                    : "Profile not verified",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color:
                                      isVerified
                                          ? AppColors.green700
                                          : AppColors.red700,
                                ),
                              ),
                              Text(
                                isVerified
                                    ? "Your profile is verified"
                                    : "Please verify your profile to enable withdrawals.",
                                style: TextStyle(
                                  color:
                                      isVerified
                                          ? AppColors.green400
                                          : AppColors.red400,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isVerified ? Icons.check_circle : Icons.cancel,
                          color:
                              isVerified
                                  ? AppColors.onlineGreen
                                  : AppColors.errorRed,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                if (isVerified) ...[
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('wallets')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                    builder: (context, walletSnapshot) {
                      final walletData = walletSnapshot.data?.data();
                      final balance = _readAmount(
                        walletData,
                        'availableBalance',
                      );
                      final totalEarned = _readAmount(
                        walletData,
                        'totalEarned',
                      );
                      final pendingBalance = _readAmount(
                        walletData,
                        'pendingBalance',
                      );

                      if (walletSnapshot.hasError) {
                        return const Text(
                          "Unable to load wallet balance.",
                          style: TextStyle(color: AppColors.errorRed),
                        );
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.10),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.04),
                              blurRadius: 2,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.purple500,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: const Icon(
                                        Icons.account_balance_wallet,
                                        color: AppColors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "Balance",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.purple500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "₹${_formatAmount(balance)}",
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.purple500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWalletStat(
                                    "Total earned",
                                    "₹${_formatAmount(totalEarned)}",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildWalletStat(
                                    "Pending",
                                    "₹${_formatAmount(pendingBalance)}",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    walletSnapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? null
                                        : () async {
                                          await handleWithdraw(
                                            context,
                                            balance,
                                          );
                                        },
                                icon: const Icon(
                                  Icons.arrow_outward,
                                  color: AppColors.white,
                                  size: 22,
                                ),
                                label: const Text(
                                  "WITHDRAW",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Bank Accounts",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Add account details to withdraw your earnings",
                          style: TextStyle(
                            color: AppColors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AddBankDetailsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 22),
                          label: const Text(
                            "ADD BANK DETAILS",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: const [
                        Icon(Icons.lock, color: AppColors.errorRed, size: 70),
                        SizedBox(height: 16),
                        Text(
                          "You need to verify your profile to add bank details and withdraw earnings.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.black54,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 38),
                Divider(
                  thickness: 1.4,
                  color: AppColors.purple100,
                  indent: 35,
                  endIndent: 35,
                ),
                const SizedBox(height: 12),
                _buildListTile(
                  icon: Icons.trending_up,
                  iconBg: AppColors.green50,
                  iconColor: AppColors.onlineGreen,
                  title: "Earnings",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EarningsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildListTile(
                  icon: Icons.trending_down,
                  iconBg: AppColors.red50,
                  iconColor: AppColors.errorRedAccent,
                  title: "Expenditures",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExpenditureScren(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildListTile(
                  icon: Icons.history,
                  iconBg: AppColors.purple50,
                  iconColor: AppColors.primaryPurple,
                  title: "Withdrawal History",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WithdrawalHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: iconColor, size: 28),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    );
  }

  Widget _buildWalletStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.purple50,
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
              color: AppColors.purple700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
