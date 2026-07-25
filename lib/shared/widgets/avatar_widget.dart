import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
  });

  Color _avatarColor(String name) {
    final colors = [
      AppColors.primary, AppColors.accent, AppColors.warning,
      const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF06B6D4),
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.textMuted.withOpacity(0.2),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialsAvatar(),
            errorWidget: (_, __, ___) => _initialsAvatar(),
          ),
        ),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    final bg = backgroundColor ?? _avatarColor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        AppHelpers.getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
