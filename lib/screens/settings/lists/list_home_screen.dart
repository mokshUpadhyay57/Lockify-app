import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lockify/components/widgets/lockify_scaffold.dart';
import 'package:lockify/screens/settings/lists/list_options.dart';

class ListHomeScreen extends StatelessWidget {
  const ListHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the platform is iOS
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return LockifyScaffold(
      title: 'Lists',
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: listOptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final option = listOptions[index];

          return Card(
            margin: EdgeInsets.zero,
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                decoration: BoxDecoration(
                  color: option.iconColor ?? Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  isIOS ? option.cupertinoIcon : option.materialIcon,
                  color: option.iconColor ?? Colors.deepPurple,
                  size: 24,
                ),
              ),
              title: Text(
                option.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle:
                  option.subtitle != null
                      ? Text(
                        option.subtitle!,
                        style: const TextStyle(color: AppColors.grey, fontSize: 13),
                      )
                      : null,
              trailing: Icon(
                isIOS ? CupertinoIcons.chevron_forward : Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.grey,
              ),
              onTap: () => option.onTap(context),
            ),
          );
        },
      ),
    );
  }
}

