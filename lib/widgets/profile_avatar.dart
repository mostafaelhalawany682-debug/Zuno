import 'package:flutter/material.dart';

import '../zuno_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.url = '', this.radius = 22});

  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = url.trim().isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: zunoPanel,
      backgroundImage: hasImage ? NetworkImage(url) : null,
      child: hasImage
          ? null
          : Icon(Icons.person_outline, color: zunoGold, size: radius),
    );
  }
}
