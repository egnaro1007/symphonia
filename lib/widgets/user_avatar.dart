import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/services/user_info_manager.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final String? avatarUrl;
  final bool isCurrentUser;
  final Color? backgroundColor;
  final String? userName;

  const UserAvatar({
    super.key,
    this.radius = 24,
    this.avatarUrl,
    this.isCurrentUser = false,
    this.backgroundColor,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    String? imageUrl;

    if (isCurrentUser) {
      // Use current user's avatar from UserInfoManager
      imageUrl = UserInfoManager.fullProfilePictureUrl;
    } else if (avatarUrl != null &&
        avatarUrl!.isNotEmpty &&
        avatarUrl != 'null') {
      // Use provided avatar URL for other users
      imageUrl = _processAvatarUrl(avatarUrl!);
    }

    // If we have a valid image URL, show the image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.blue.shade100,
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildDefaultAvatar();
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar();
            },
          ),
        ),
      );
    }

    // Fallback to default avatar
    return _buildDefaultAvatar();
  }

  String? _processAvatarUrl(String url) {
    if (url.isEmpty || url == 'null') return null;

    // If URL already starts with http, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Add server URL prefix if it's a relative path
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    if (serverUrl.isNotEmpty && url.startsWith('/')) {
      // Ensure server URL doesn't end with slash
      if (serverUrl.endsWith('/')) {
        serverUrl = serverUrl.substring(0, serverUrl.length - 1);
      }
      return '$serverUrl$url';
    }

    return url;
  }

  Widget _buildDefaultAvatar() {
    // Try to create initials if userName is provided
    if (userName != null && userName!.isNotEmpty) {
      String initials = _getInitials(userName!);
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.blue.shade100,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: radius * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Default icon avatar
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.blue.shade100,
      child: Icon(
        Icons.person,
        size: radius * 0.8,
        color: Colors.blue.shade600,
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return '?';
  }
}
