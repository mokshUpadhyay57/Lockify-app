import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';

class MemberTile extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String role; // 'Owner', 'Admin', 'Member'
  final bool canManage; // If the current user can manage this member
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback? onRemove;

  const MemberTile({
    super.key,
    required this.userData,
    required this.role,
    this.canManage = false,
    this.onPromote,
    this.onDemote,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = userData['name'] ?? userData['username'] ?? 'User';
    final photoUrl = userData['photoUrl'];
    final phone = userData['phone'] ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.purple100,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: phone.isNotEmpty ? Text(phone) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoleBadge(),
          if (canManage && role != 'Owner')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'promote') onPromote?.call();
                if (value == 'demote') onDemote?.call();
                if (value == 'remove') onRemove?.call();
              },
              itemBuilder: (context) => [
                if (role == 'Member')
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('Promote to Admin'),
                  ),
                if (role == 'Admin')
                  const PopupMenuItem(
                    value: 'demote',
                    child: Text('Demote from Admin'),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove from Group', style: TextStyle(color: AppColors.errorRed)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color badgeColor;
    String label;

    switch (role) {
      case 'Owner':
        badgeColor = AppColors.warningOrange;
        label = 'Owner';
        break;
      case 'Admin':
        badgeColor = AppColors.primaryPurple;
        label = 'Admin';

        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

