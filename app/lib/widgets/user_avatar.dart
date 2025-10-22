import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final double? iconSize;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final defaultIconSize = iconSize ?? radius;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Icon(Icons.person, color: Colors.white, size: defaultIconSize),
            errorWidget: (context, url, error) =>
                Icon(Icons.person, color: Colors.white, size: defaultIconSize),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(Icons.person, color: Colors.white, size: defaultIconSize),
    );
  }
}
