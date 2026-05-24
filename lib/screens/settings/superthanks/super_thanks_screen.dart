import 'package:lockify/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lockify/screens/settings/superthanks/recieved_gift_screen.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';

class SuperThanksScreen extends StatelessWidget {
  const SuperThanksScreen({super.key});

  Future<String> _loadUniqueLink() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "lockify.co.in/st/guest";

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    final username = data['username']?.toString().trim();
    final handle =
        username != null && username.isNotEmpty
            ? username
            : user.email?.split('@').first.trim();

    return "lockify.co.in/st/${handle == null || handle.isEmpty ? user.uid : handle}";
  }

  String _shareText(String uniqueLink) {
    return "You can send me a Super Thanks on Lockify: $uniqueLink";
  }

  @override
  Widget build(BuildContext context) {
    return LockifyScaffold(
      backgroundColor: const Color(0xFF6A1B9A),
      title: "Super Thanks",
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceivedGiftScreen()));
          },
          child: const Padding(
            padding: EdgeInsets.only(right: 25),
            child: Icon(Icons.group, color: AppColors.white),
          ),
        ),
      ],
      body: FutureBuilder<String>(
        future: _loadUniqueLink(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.white));
          }

          final uniqueLink = snapshot.data ?? "lockify.co.in/st/guest";
          final shareText = _shareText(uniqueLink);

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 8,
                  shadowColor: const Color(0xFF6A1B9A).withValues(alpha: 0.18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, color: Color(0xFF6A1B9A), size: 54),
                        const SizedBox(height: 14),
                        const Text(
                          "Super Thanks",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color(0xFF6A1B9A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Receive monetary gifts from fans by sharing your Super Thanks link.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.black87, fontSize: 16),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.green50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.green200, width: 1.4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link, color: AppColors.onlineGreen, size: 22),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  uniqueLink,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: AppColors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await SharePlus.instance.share(
                                  ShareParams(
                                    text: shareText,
                                    subject: "Super Thanks Link",
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share),
                              label: const Text("Share"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A1B9A),
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                            ),
                            const SizedBox(width: 18),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: shareText));
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text("Copy"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green600,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

