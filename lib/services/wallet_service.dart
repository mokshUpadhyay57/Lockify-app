import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's UID
  String? get _uid => _auth.currentUser?.uid;

  // Stream of the user's wallet document
  Stream<DocumentSnapshot<Map<String, dynamic>>> getWalletStream() {
    if (_uid == null) return const Stream.empty();
    return _firestore.collection('wallets').doc(_uid).snapshots();
  }

  // Stream of all transactions for the current user
  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactionsStream() {
    if (_uid == null) return const Stream.empty();
    return _firestore
        .collection('wallet_transactions')
        .where('userId', isEqualTo: _uid)
        .snapshots();
  }

  // Format amount for display
  String formatAmount(dynamic amount) {
    if (amount == null) return "0.00";
    if (amount is num) return amount.toStringAsFixed(2);
    if (amount is String) return double.tryParse(amount)?.toStringAsFixed(2) ?? "0.00";
    return "0.00";
  }

  // Read amount from a dynamic value (handling both double and int)
  double readAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Determine if a transaction is a debit (expenditure)
  bool isDebit(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';
    final status = data['status']?.toString().toLowerCase() ?? '';
    
    // Expenditure or withdrawal
    return type == 'expenditure' || type == 'withdrawal' || status == 'debit';
  }
}
