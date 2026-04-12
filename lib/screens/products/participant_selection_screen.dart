import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:lockify/utils/contacts.dart';
import 'package:lockify/utils/snackbar.dart';


class ParticipantSelectionScreen extends StatefulWidget {
  final String title;
  final String buttonLabel;
  final Future<void> Function(List<String> selectedPhones) onConfirm;

  const ParticipantSelectionScreen({
    super.key,
    required this.title,
    this.buttonLabel = 'Add',
    required this.onConfirm,
  });

  @override
  State<ParticipantSelectionScreen> createState() => _ParticipantSelectionScreenState();
}

class _ParticipantSelectionScreenState extends State<ParticipantSelectionScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  Set<Contact> selectedContacts = {};
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    final fetchedContacts = await getContacts(context);
    setState(() {
      contacts = fetchedContacts;
      filteredContacts = fetchedContacts;
    });
  }

  void _filterContacts(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      filteredContacts =
          contacts.where((contact) => contact.displayName.toLowerCase().contains(lowerCaseQuery)).toList();
    });
  }

  void _toggleContactSelection(Contact contact) {
    setState(() {
      if (selectedContacts.contains(contact)) {
        selectedContacts.remove(contact);
      } else {
        selectedContacts.add(contact);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 18)),
        centerTitle: false,
        leadingWidth: 35,
        actions: [
          if (isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: selectedContacts.isEmpty ? null : () async {
                setState(() => isSubmitting = true);
                try {
                  final List<String> participantPhones = selectedContacts
                      .where((c) => c.phones.isNotEmpty)
                      .map((c) => c.phones.first.number.replaceAll(RegExp(r'\D'), ''))
                      .map((p) => p.length >= 10 ? p.substring(p.length - 10) : p)
                      .toList();

                  await widget.onConfirm(participantPhones);
                  
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    AppSnackBar.error(context, 'Error: ${e.toString()}');
                  }
                } finally {
                  if (mounted) setState(() => isSubmitting = false);
                }
              },
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.purple100,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              '${selectedContacts.length} Selected',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: searchController,
              onChanged: _filterContacts,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: filteredContacts.isEmpty
                ? const Center(child: Text('No contacts found.'))
                : ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final isSelected = selectedContacts.contains(contact);
                      return ListTile(
                        onTap: () => _toggleContactSelection(contact),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.purple100,
                          child: Text(
                            contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(contact.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : 'No phone'),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? AppColors.primaryPurple : AppColors.grey,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

