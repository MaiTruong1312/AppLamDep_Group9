import 'package:flutter/material.dart';

Widget buildSmartImage(String path, {BoxFit fit = BoxFit.cover}) {
  if (path.isEmpty) {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  // Logic nhận diện asset hay network
  if (path.startsWith('assets/')) {
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  return Image.network(
    path,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => Container(
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    ),
  );
}