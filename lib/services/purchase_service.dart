import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lockify/utils/app_logger.dart';

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  /// Get a stream of purchases for the current logged-in user
  Stream<List<QueryDocumentSnapshot>> streamMyPurchases() {
    final currentUser = _auth.currentUser;
    AppLogger.info("Fetching purchases for user: ${currentUser?.uid}");
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('order-items')
        .where('buyerId', isEqualTo: currentUser.uid)
        .orderBy('purchasedAt', descending: true)
        .limit(20) // Optimization: Limit to latest 20 purchases
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Get the locked message details for a given lockedMessageId
  Future<DocumentSnapshot<Map<String, dynamic>>> getLockedMessage(
    String messageId,
  ) {
    return _firestore.collection('lockedMessages').doc(messageId).get();
  }
}
