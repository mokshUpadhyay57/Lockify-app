import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/screens/settings/earning/earning_home_screen.dart';
import 'package:lockify/screens/settings/lists/list_home_screen.dart';
import 'package:lockify/screens/settings/profile/profile_screen.dart';
import 'package:lockify/screens/settings/dashboard/dashboard_screen.dart';
import 'package:lockify/screens/settings/superthanks/super_thanks_screen.dart';
import 'package:lockify/screens/settings/setting/settings_screen.dart';
import 'package:lockify/screens/settings/verification/profile_verification_screen.dart';
import 'package:lockify/screens/settings/wallet/wallet_home_screen.dart';

class SettingItem {
  final IconData iosIcon;
  final IconData androidIcon;
  final String title;
  final Widget page;

  const SettingItem({ // Make constructor const
    required this.iosIcon,
    required this.androidIcon,
    required this.title,
    required this.page,
  });
}

class SettingHomePage extends StatelessWidget {
  const SettingHomePage({super.key});

  static const double _itemSpacing = 10.0;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final Color primaryColor = AppColors.primaryPurple;
    final Color surfaceColor = AppColors.purple50;

    // Use const for lists and their items
    final List<SettingItem> generalItems = const [
      SettingItem(
        iosIcon: CupertinoIcons.person,
        androidIcon: Icons.person,
        title: "My Profile",
        page: ProfileScreen(),
      ),
      SettingItem(
        iosIcon: CupertinoIcons.square_grid_2x2,
        androidIcon: Icons.dashboard,
        title: "Dashboard",
        page: DashboardScreen(),
      ),
      SettingItem(
        iosIcon: CupertinoIcons.gift,
        androidIcon: Icons.card_giftcard_sharp,
        title: "Super Thanks",
        page: SuperThanksScreen(),
      ),
      SettingItem(
        iosIcon: CupertinoIcons.settings,
        androidIcon: Icons.settings,
        title: "Settings",
        page: SettingsPage(),
      ),
      SettingItem(
        iosIcon: CupertinoIcons.list_bullet,
        androidIcon: Icons.list,
        title: "Lists",
        page: ListHomeScreen(),
      ),
      SettingItem(
        iosIcon: Icons.verified_user,
        androidIcon: Icons.verified_user,
        title: "Verification",
        page: ProfileVerificationScreen(),
      ),
    ];

    final List<SettingItem> accountItems = const [
      SettingItem(
        iosIcon: CupertinoIcons.money_dollar,
        androidIcon: Icons.account_balance,
        title: "Earnings",
        page: EarningHomeScreen(),
      ),
      SettingItem(
        iosIcon: CupertinoIcons.square_arrow_right,
        androidIcon: Icons.account_balance_wallet,
        title: "Wallet",
        page: WalletHomeScreen(),
      ),
    ];

    return LockifyScaffold(
      showAppBar: false,
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
          children: [
            _buildSectionHeader("General", primaryColor),
            ..._buildSettingList(context, generalItems, isIOS, primaryColor),
            const SizedBox(height: 28.0),
            _buildSectionHeader("Account", primaryColor),
            ..._buildSettingList(context, accountItems, isIOS, primaryColor),
            const SizedBox(height: 36.0), // extra bottom space for comfort
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Divider(
              thickness: 1.0,
              color: AppColors.purple100,
              endIndent: 10.0,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSettingList(BuildContext context, List<SettingItem> items, bool isIOS, Color primaryColor) {
    return [
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: _itemSpacing),
        itemBuilder: (context, i) => _buildModernTile(
          context,
          icon: isIOS ? items[i].iosIcon : items[i].androidIcon,
          title: items[i].title,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => items[i].page),
            );
          },
          primaryColor: primaryColor,
        ),
      ),
    ];
  }

  Widget _buildModernTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
      child: Material(
        color: AppColors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(icon, color: primaryColor, size: 25.0),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 20.0, color: AppColors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

