import 'package:lockify/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:lockify/utils/snackbar.dart';


class AddBankDetailsScreen extends StatefulWidget {
  const AddBankDetailsScreen({super.key});

  @override
  State<AddBankDetailsScreen> createState() => _AddBankDetailsScreenState();
}

class _AddBankDetailsScreenState extends State<AddBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final logger = Logger();

  // Use a map for controllers, just like in profile_update_screen.dart
  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'bankAccount': TextEditingController(),
    'ifsc': TextEditingController(),
    'vpa': TextEditingController(),
    'address': TextEditingController(),
    'city': TextEditingController(),
    'state': TextEditingController(),
    'postalCode': TextEditingController(),
  };


  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> splitPhoneWithCountryCode(String input) {
    final regExp = RegExp(r'^(\+\d{1,4})(\d{6,})$');
    final match = regExp.firstMatch(input.replaceAll(' ', ''));
    if (match != null) {
      return {'countryCode': match.group(1)!, 'phone': match.group(2)!};
    } else {
      return {'countryCode': '', 'phone': input};
    }
  }

  String _generateBeneficiaryId() {
    return controllers['name']!.text +
        controllers['ifsc']!.text +
        DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackBar.error(context, "You must be signed in to add a beneficiary.");
      logger.e('User not authenticated');
      return;
    }

    if (_formKey.currentState!.validate()) {
      final idToken = await user.getIdToken(true);
      final splitPhone = splitPhoneWithCountryCode(controllers['phone']!.text);
      final beneficiaryId = _generateBeneficiaryId();

      try {
        final response = await http.post(
          Uri.parse("https://addbeneficiary-eof7ol2ifa-uc.a.run.app/addBeneficiary"),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
          body: jsonEncode({
            "beneficiary_id": beneficiaryId,
            "beneficiary_name": controllers['name']!.text,
            "beneficiary_instrument_details": {
              "bank_account_number": controllers['bankAccount']!.text,
              "bank_ifsc": controllers['ifsc']!.text,
              "vpa": controllers['vpa']!.text.isNotEmpty ? controllers['vpa']!.text : null,
            },
            "beneficiary_contact_details": {
              "beneficiary_email": controllers['email']!.text,
              "beneficiary_phone": splitPhone['phone'],
              "beneficiary_country_code": splitPhone['countryCode'],
              "beneficiary_address": controllers['address']!.text,
              "beneficiary_city": controllers['city']!.text,
              "beneficiary_state": controllers['state']!.text,
              "beneficiary_postal_code": controllers['postalCode']!.text,
              "beneficiary_purpose": "Withdrawal",
            },
          }),
        );

        logger.i('API response: ${response.body}');

        if (response.statusCode == 200) {
          AppSnackBar.success(context, "Beneficiary added successfully!");
        } else {
          logger.e('Error from function: ${response.body}');
          AppSnackBar.error(context, "Error: ${response.body}");
        }
      } catch (e, stack) {
        logger.e('Exception during submission', error: e, stackTrace: stack);
        AppSnackBar.error(context, "Error");
      }
    }
  }

  final List<Map<String, dynamic>> _fields = [
    {"label": "Name", "key": "name", "icon": Icons.person},
    {"label": "Email", "key": "email", "icon": Icons.email, "keyboardType": TextInputType.emailAddress},
    {"label": "Phone with Country Code", "key": "phone", "icon": Icons.phone, "keyboardType": TextInputType.phone},
    {"label": "Bank Account", "key": "bankAccount", "icon": Icons.account_balance, "keyboardType": TextInputType.number},
    {"label": "IFSC Code", "key": "ifsc", "icon": Icons.confirmation_number},
    {"label": "UPI Id", "key": "vpa", "icon": Icons.payment},
    {"label": "Address", "key": "address", "icon": Icons.home},
    {"label": "City", "key": "city", "icon": Icons.location_city},
    {"label": "State", "key": "state", "icon": Icons.map},
    {"label": "Postal Code", "key": "postalCode", "icon": Icons.pin_drop, "keyboardType": TextInputType.number},
  ];

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Color primaryColor, {
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
          labelText: label,
          labelStyle: TextStyle(color: primaryColor),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppColors.primaryPurple;
    final Color surfaceColor = AppColors.purple50;
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        title: const Text("Add Bank Details"),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.purple100.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.purple200, width: 1.5),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryPurple, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Bank account details should match with the PAN details provided during KYC Process",
                        style: TextStyle(color: AppColors.purple700, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.all(20),
              elevation: 3,
              shadowColor: AppColors.purple100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._fields.map((f) => _buildTextField(
                        f["label"],
                        controllers[f["key"]]!,
                        primaryColor,
                        keyboardType: f["keyboardType"] ?? TextInputType.text,
                        icon: f["icon"],
                      )),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 55,
                        width: 280,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            elevation: 2,
                          ),
                          onPressed: _submitForm,
                          label: const Text("Submit"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

