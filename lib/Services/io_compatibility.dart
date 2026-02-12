import 'dart:io';
import 'package:flutter/material.dart';

export 'dart:io';

Widget getImageFromFile(String path) {
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
  );
}

ImageProvider getImageProviderFromFile(String path) {
  return FileImage(File(path));
}
