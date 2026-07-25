import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/user_model.dart';

class VisibilityBadge extends StatelessWidget {
  final ContentVisibility visibility;
  final bool showIcon;

  const VisibilityBadge({super.key, required this.visibility, this.showIcon = true});

  Color get _color {
    switch (visibility) {
      case ContentVisibility.private: return AppColors.privateColor;
      case ContentVisibility.friendsOnly: return AppColors.friendsColor;
      case ContentVisibility.public: return AppColors.publicColor;
    }
  }

  IconData get _icon {
    switch (visibility) {
      case ContentVisibility.private: return Icons.lock_outline;
      case ContentVisibility.friendsOnly: return Icons.people_outline;
      case ContentVisibility.public: return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_icon, size: 12, color: _color),
            const SizedBox(width: 4),
          ],
          Text(
            visibility.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
          ),
        ],
      ),
    );
  }
}
