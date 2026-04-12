import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final CollectionReference adminCollection =
      FirebaseFirestore.instance.collection('adminUser');

  /// Returns the UID of the admin user.
  Future<String?> getAdminByUid() async {
    final snapshot = await adminCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id; // Assuming UID is the document ID
    }
    return null;
  }

  /// Returns a list of all admin UIDs (if you have multiple admins).
  Future<List<String>> getAllAdminUids() async {
    final snapshot = await adminCollection.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
