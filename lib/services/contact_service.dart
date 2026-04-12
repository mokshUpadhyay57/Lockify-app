import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lockify/utils/contacts.dart';

class ContactService {
  // Singleton pattern
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  List<Contact>? _cachedContacts;
  bool _isLoading = false;

  Future<List<Contact>> getCachedContacts(BuildContext context) async {
    if (_cachedContacts != null) return _cachedContacts!;
    
    // Prevent multiple simultaneous fetches
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedContacts ?? [];
    }

    _isLoading = true;
    try {
      _cachedContacts = await getContacts(context);
    } finally {
      _isLoading = false;
    }
    
    return _cachedContacts ?? [];
  }

  void invalidateCache() {
    _cachedContacts = null;
  }
}
