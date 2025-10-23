import "dart:io";
import "package:flutter/material.dart";

class CoverImagePicker extends StatelessWidget {
  final File? coverImage;
  final VoidCallback onTap;

  const CoverImagePicker({
    required this.coverImage,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (coverImage != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(coverImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2433),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2D3748), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6949FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 20,
                color: Color(0xFF6949FF),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Tap to add cover image",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
