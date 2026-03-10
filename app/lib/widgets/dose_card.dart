import 'package:flutter/material.dart';

class DoseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const DoseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 0,
      margin: margin ?? const EdgeInsets.only(bottom: 12.0),
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 3.0,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: padding == EdgeInsets.zero
            ? child
            : Padding(
                padding: padding ?? const EdgeInsets.all(16.0),
                child: child,
              ),
      ),
    );

    return card;
  }
}
