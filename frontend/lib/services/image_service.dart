import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

// Classe pour stocker les données d'image
class ImageData {
  final XFile file;
  final String? previewUrl;

  ImageData(this.file, {this.previewUrl});
}

// Interface abstraite pour la gestion des images
abstract class ImageService {
  Future<ImageData?> pickImage();
  Widget buildImagePreview(ImageData imageData);
  Future<List<int>> getImageBytes(ImageData imageData);
  void dispose(ImageData? imageData);
}

// Implémentation pour le Web
class WebImageService implements ImageService {
  @override
  Future<ImageData?> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        return ImageData(image);
      }
      return ImageData(image);
    }
    return null;
  }

  @override
  Widget buildImagePreview(ImageData imageData) {
    return FutureBuilder<Uint8List>(
      future: imageData.file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Future<List<int>> getImageBytes(ImageData imageData) async {
    return await imageData.file.readAsBytes();
  }

  @override
  void dispose(ImageData? imageData) {
    // Rien à faire pour le web
  }
}

// Implémentation pour Mobile
class MobileImageService implements ImageService {
  @override
  Future<ImageData?> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return ImageData(image);
    }
    return null;
  }

  @override
  Widget buildImagePreview(ImageData imageData) {
    return FutureBuilder<Uint8List>(
      future: imageData.file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Future<List<int>> getImageBytes(ImageData imageData) async {
    return await imageData.file.readAsBytes();
  }

  @override
  void dispose(ImageData? imageData) {
    // Rien à faire pour mobile
  }
}

// Factory pour créer le bon service selon la plateforme
class ImageServiceFactory {
  static ImageService create() {
    if (kIsWeb) {
      return WebImageService();
    } else {
      return MobileImageService();
    }
  }
}
