import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AppFileImage extends StatelessWidget {
  final XFile? xFile;
  final File? file;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppFileImage({
    super.key,
    this.xFile,
    this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : assert(xFile != null || file != null);

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (kIsWeb) {
      if (xFile != null) {
        image = FutureBuilder<Uint8List>(
          future: xFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: width,
                height: height,
                fit: fit,
              );
            }
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade800,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              ),
            );
          },
        );
      } else {
        image = Container(
          width: width,
          height: height,
          color: Colors.grey.shade800,
          child: const Icon(Icons.image, color: Colors.white70),
        );
      }
    } else {
      final localFile = file ?? (xFile != null ? File(xFile!.path) : null);
      if (localFile != null) {
        image = Image.file(
          localFile,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.grey.shade800,
            child: const Icon(Icons.broken_image, color: Colors.white70),
          ),
        );
      } else {
        image = Container(
          width: width,
          height: height,
          color: Colors.grey.shade800,
          child: const Icon(Icons.image, color: Colors.white70),
        );
      }
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
