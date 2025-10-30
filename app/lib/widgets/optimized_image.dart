import 'package:flutter/material.dart';

/// An optimized image widget that replaces CachedNetworkImage
/// Uses cacheWidth/cacheHeight to decode images at specific sizes
/// This reduces memory consumption significantly during hot reload
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? cacheWidth;
  final int? cacheHeight;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate cache dimensions based on device pixel ratio
    // Skip calculation for infinite dimensions (double.infinity)
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final calculatedCacheWidth =
        cacheWidth ??
        (width != null && width!.isFinite
            ? (width! * devicePixelRatio).round()
            : null);
    final calculatedCacheHeight =
        cacheHeight ??
        (height != null && height!.isFinite
            ? (height! * devicePixelRatio).round()
            : null);

    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: calculatedCacheWidth,
      cacheHeight: calculatedCacheHeight,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _defaultPlaceholder(context);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _defaultErrorWidget(context);
      },
    );

    // Wrap with RepaintBoundary to isolate repaints
    imageWidget = RepaintBoundary(child: imageWidget);

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surface,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surface,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        size: 32,
      ),
    );
  }
}

/// Optimized circular avatar image
class OptimizedAvatarImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedAvatarImage({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheSize = (diameter * devicePixelRatio).round();

    return RepaintBoundary(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Error handled by child widget
        },
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            cacheWidth: cacheSize,
            cacheHeight: cacheSize,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame == null && !wasSynchronouslyLoaded) {
                return placeholder ?? _defaultPlaceholder(context);
              }
              return const SizedBox.shrink(); // Let CircleAvatar handle it
            },
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? _defaultErrorWidget(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Theme.of(context).colorScheme.surface,
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: Icon(
        Icons.person,
        color: Theme.of(context).colorScheme.primary,
        size: radius,
      ),
    );
  }
}
