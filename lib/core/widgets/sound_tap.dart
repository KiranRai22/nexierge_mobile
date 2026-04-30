import 'package:flutter/material.dart';

import '../services/sound_manager.dart';

/// A wrapper widget that plays a sound on tap.
/// Makes it easy to add sound feedback to any tappable widget.
class SoundTap extends StatelessWidget {
  final Widget child;
  final SoundCategory soundCategory;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapDownCallback? onTapDown;
  final bool enabled;

  const SoundTap({
    super.key,
    required this.child,
    this.soundCategory = SoundCategory.button,
    this.onTap,
    this.onLongPress,
    this.onTapCancel,
    this.onTapDown,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () async {
              await SoundManager.instance.play(soundCategory);
              onTap?.call();
            }
          : onTap,
      onLongPress: enabled
          ? () async {
              await SoundManager.instance.play(soundCategory);
              onLongPress?.call();
            }
          : onLongPress,
      onTapCancel: onTapCancel,
      onTapDown: onTapDown,
      child: child,
    );
  }
}

/// A wrapper for IconButton that plays a sound on tap.
class SoundIconButton extends StatelessWidget {
  final IconData icon;
  final SoundCategory soundCategory;
  final VoidCallback? onPressed;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;

  const SoundIconButton({
    super.key,
    required this.icon,
    this.soundCategory = SoundCategory.button,
    this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: iconSize, color: color),
      onPressed: enabled
          ? () async {
              await SoundManager.instance.play(soundCategory);
              onPressed?.call();
            }
          : onPressed,
      tooltip: tooltip,
    );
  }
}
