import 'package:flutter/material.dart';

/// Validates and sanitizes image URLs before loading them
class ImageHelper {
  /// Validates if the provided URL is a valid network image URL
  /// Returns the URL if valid, null otherwise
  static String? validateImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    // Check if it's a valid URL
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) {
      return null;
    }

    // Check if it has a valid scheme (http or https)
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    // Check if it has a valid host
    if (uri.host.isEmpty) {
      return null;
    }

    return url;
  }

  /// Creates a NetworkImage with proper validation
  /// Returns null if the URL is invalid
  static NetworkImage? createValidNetworkImage(String? url) {
    final validUrl = validateImageUrl(url);
    if (validUrl != null) {
      return NetworkImage(validUrl);
    }
    return null;
  }
}
