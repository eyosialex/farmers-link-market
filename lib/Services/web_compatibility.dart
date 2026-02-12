import 'package:flutter/material.dart';
import 'local_storage_service.dart';
import '../Farmers View/FireStore_Config.dart';
import '../Farmers View/Sell_Item_Model.dart';


// Stub for dart:io File
class File {
  final String path;
  File(this.path);

  Future<bool> exists() async {
    return true; // Stub always returns true
  }
}

Widget getImageFromFile(String path) {
  // On web, XFile path is a blob URL, so we can use NetworkImage or Image.network
  return Image.network(
    path,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
  );
}

ImageProvider getImageProviderFromFile(String path) {
  return NetworkImage(path);
}
