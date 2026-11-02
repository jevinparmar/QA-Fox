import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget Function(BuildContext, String)? placeholder;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Data = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Data);
        image = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, err, stack) => errorWidget != null
              ? errorWidget!(ctx, url, err)
              : const Center(child: Icon(Icons.broken_image)),
        );
      } catch (e) {
        image = errorWidget != null
            ? errorWidget!(context, url, e)
            : const Center(child: Icon(Icons.broken_image));
      }
    } else {
      final cacheW = width != null && width!.isFinite && width! > 0
          ? (width! * 2).toInt()
          : null;
      final cacheH = height != null && height!.isFinite && height! > 0
          ? (height! * 2).toInt()
          : null;

      image = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 150),
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        placeholder: placeholder,
        errorWidget:
            errorWidget ??
            (ctx, u, err) => const Center(child: Icon(Icons.broken_image)),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
