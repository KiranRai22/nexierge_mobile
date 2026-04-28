import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart' as ip;

/// Source the user picked in the change-avatar bottom sheet.
/// Defined locally so the widget layer never imports `image_picker` directly.
enum ImageSource$ { gallery, camera }

/// Picks an image from the gallery or camera and compresses it before
/// returning a `File` ready for multipart upload. Compression is capped
/// at 80 % quality and 1080 px on the longest edge — plenty for an
/// avatar, but small enough to keep upload fast on hotel Wi-Fi.
class ImagePickerService {
  ImagePickerService({ip.ImagePicker? picker})
      : _picker = picker ?? ip.ImagePicker();

  final ip.ImagePicker _picker;

  static const int _maxDimension = 1080;
  static const int _quality = 80;

  /// Pick an image from [source], compress it, and return the compressed
  /// file. Returns `null` if the user cancelled the picker.
  Future<File?> pickAndCompress(ImageSource$ source) async {
    final ip.XFile? picked = await _picker.pickImage(
      source: source == ImageSource$.gallery
          ? ip.ImageSource.gallery
          : ip.ImageSource.camera,
      imageQuality: 100, // we compress ourselves below
      maxWidth: _maxDimension.toDouble(),
      maxHeight: _maxDimension.toDouble(),
    );
    if (picked == null) return null;

    final originalFile = File(picked.path);
    return _compress(originalFile);
  }

  Future<File> _compress(File source) async {
    final dir = source.parent.path;
    final targetPath =
        '$dir${Platform.pathSeparator}avatar_'
        '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      targetPath,
      quality: _quality,
      minWidth: _maxDimension,
      minHeight: _maxDimension,
      format: CompressFormat.jpeg,
    );

    // Compression failed — fall back to the raw picked file which is already
    // capped to maxWidth/maxHeight by the picker.
    if (result == null) return source;
    return File(result.path);
  }
}
