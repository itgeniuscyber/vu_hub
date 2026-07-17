import 'package:flutter/widgets.dart';
import 'package:fui_kit/fui_kit.dart' as fui;

export 'package:fui_kit/fui_kit.dart' hide FUI;

class FUI extends StatelessWidget {
  const FUI(
    this.file, {
    super.key,
    this.width,
    this.height,
    this.color,
    this.semanticLabel,
    this.fit = BoxFit.contain,
    this.matchTextDirection = false,
  });

  final String file;
  final double? width;
  final double? height;
  final Color? color;
  final String? semanticLabel;
  final BoxFit fit;
  final bool matchTextDirection;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final fallbackSize = iconTheme.size ?? 24;
    final resolvedWidth = width ?? fallbackSize;
    final resolvedHeight = height ?? fallbackSize;

    return Align(
      alignment: Alignment.center,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: resolvedWidth,
        height: resolvedHeight,
        child: FittedBox(
          fit: fit,
          child: fui.FUI(
            file,
            width: resolvedWidth,
            height: resolvedHeight,
            color: color,
            semanticLabel: semanticLabel,
            matchTextDirection: matchTextDirection,
          ),
        ),
      ),
    );
  }
}
