import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lockify/screens/settings/superthanks/recieved_gift_screen.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';


class SuperThanksScreen extends StatelessWidget {
  final String uniqueLink = "lockify.co.in/st/Moksh57";
  String get shareLink =>
      "You can send me a super Thanks! Just tap the link to show your support $uniqueLink"; // Example link

  const SuperThanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LockifyScaffold(
      backgroundColor: const Color(0xFF6A1B9A), // Purple background
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
      body: Center(
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

                    // Super thanks link with icon
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
                          Text(
                            uniqueLink,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Share & Copy buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await SharePlus.instance.share(
                              ShareParams(
                                text: shareLink,
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
                            await Clipboard.setData(ClipboardData(text: shareLink));
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
      ),
    );
  }
}

