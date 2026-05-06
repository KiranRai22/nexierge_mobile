import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart' as ip;

/// Source the user picked in the change-avatar bottom sheet.
/// Defined locally so the widget layer never imports `image_picker` directly.
enum ImageSource$ { gallery, camera }

/// Picks an image from the gallery or camera and compresses it before
/// returning a `File` ready for multipart upload. The result is capped
/// to ~500 KB by iteratively lowering JPEG quality, so uploads stay
/// fast on hotel Wi-Fi without doubling bytes server-side.
class ImagePickerService {
  ImagePickerService({ip.ImagePicker? picker})
      : _picker = picker ?? ip.ImagePicker();

  final ip.ImagePicker _picker;

  // Picker output upper bound — large enough that the server thumbnail
  // pipeline still has detail to work with, small enough that a single
  // compression pass usually lands under [_targetBytes].
  static const int _maxDimension = 1080;

  // Target file size for the uploaded avatar.
  static const int _targetBytes = 500 * 1024;

  // Iterative-compression quality ladder. Starts high so a typical
  // phone-camera JPEG lands at first try; drops fast if the image is
  // huge (e.g. raw 12 MP capture on a flagship).
  static const List<int> _qualityLadder = [85, 70, 55, 40, 25];

  /// Pick an image from [source], compress it to ≤500 KB, and return
  /// the compressed file. Returns `null` if the user cancelled the
  /// picker.
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

    return _compressToTarget(File(picked.path));
  }

  Future<File> _compressToTarget(File source) async {
    final dir = source.parent.path;
    final stamp = DateTime.now().millisecondsSinceEpoch;

    File best = source;
    int bestSize = await source.length();

    for (var i = 0; i < _qualityLadder.length; i++) {
      final quality = _qualityLadder[i];
      final targetPath =
          '$dir${Platform.pathSeparator}avatar_${stamp}_q$quality.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        targetPath,
        quality: quality,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        format: CompressFormat.jpeg,
      );
      if (result == null) continue;

      final out = File(result.path);
      final size = await out.length();

      if (size < bestSize) {
        best = out;
        bestSize = size;
      }
      if (size <= _targetBytes) return out;
    }

    // Could not hit the target — return the smallest variant produced.
    return best;
  }
}
