import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:lockify/utils/snackbar.dart';

final Logger _logger = Logger();

Future<List<Contact>> getContacts(BuildContext context) async {
  try {
    // We only read contacts in this app flow, so request read-only access.
    final hasPermission = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Contacts permission denied. Enable it in app settings.');
      }
      return [];
    }
    return await FlutterContacts.getContacts(
      withProperties: true,
    );
  } catch (e, stackTrace) {
    _logger.e('Failed to load contacts', error: e, stackTrace: stackTrace);

    if (context.mounted) {
      AppSnackBar.error(context, 'Could not load contacts. Please check your permissions or try again.');
    }
    return [];
  }
}



