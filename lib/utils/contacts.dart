import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:lockify/utils/app_logger.dart';
import 'package:lockify/utils/snackbar.dart';

Future<List<Contact>> getContacts(BuildContext context) async {
  try {
    // We only read contacts in this app flow, so request read-only access.
    final permission = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.limited) {
      if (context.mounted) {
        AppSnackBar.error(
          context,
          'Contacts permission denied. Enable it in app settings.',
        );
      }
      return [];
    }
    return await FlutterContacts.getAll(properties: {ContactProperty.phone});
  } catch (e, stackTrace) {
    AppLogger.error(
      'Failed to load contacts',
      error: e,
      stackTrace: stackTrace,
    );

    if (context.mounted) {
      AppSnackBar.error(
        context,
        'Could not load contacts. Please check your permissions or try again.',
      );
    }
    return [];
  }
}
