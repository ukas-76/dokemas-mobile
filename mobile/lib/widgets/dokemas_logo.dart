import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DokemasLogo extends StatelessWidget {
  final double width;
  final double height;
  final BoxFit fit;

  const DokemasLogo({
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/assets/logo_dokemas.png',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback ke vector dok.svg jika bundle PNG baru memerlukan restart aplikasi
        return SvgPicture.asset(
          'lib/assets/dok.svg',
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}

