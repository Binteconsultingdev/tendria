import 'package:tendria/features/feed/presentation/widget/reaction_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';

/// Barra flotante con las reacciones, anclada sobre el botón que la abre.
Future<void> showReactionPopover({
  required BuildContext context,
  required Rect anchor,
  required String? current,
  required ValueChanged<String> onSelected,
}) {
  HapticFeedback.mediumImpact();

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'reactions',
    barrierColor: Colors.black.withValues(alpha: 0.12),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, _, __) {
      final media = MediaQuery.of(ctx);
      const itemSize = 46.0;
      final width = reactionOrder.length * (itemSize + 4) + 20;
      final left = (anchor.left - 6).clamp(8.0, media.size.width - width - 8);
      var top = anchor.top - 68;
      if (top < media.padding.top + 8) top = anchor.bottom + 10;

      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: ThemeColor.cardBackground,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < reactionOrder.length; i++)
                      _PopEmoji(
                        index: i,
                        type: reactionOrder[i],
                        selected: reactionOrder[i] == current,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(ctx).pop();
                          onSelected(reactionOrder[i]);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (ctx, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        alignment: Alignment.bottomLeft,
        child: child,
      ),
    ),
  );
}

class _PopEmoji extends StatefulWidget {
  final int index;
  final String type;
  final bool selected;
  final VoidCallback onTap;

  const _PopEmoji({required this.index, required this.type, required this.selected, required this.onTap});

  @override
  State<_PopEmoji> createState() => _PopEmojiState();
}

class _PopEmojiState extends State<_PopEmoji> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Entrada escalonada: cada emoji aparece un instante después del anterior
      duration: Duration(milliseconds: 220 + widget.index * 45),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v.clamp(0.0, 1.3), child: child),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 1.4 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.selected ? ThemeColor.primaryColor.withValues(alpha: 0.16) : null,
            ),
            child: ReactionIcon(type: widget.type, size: 34),
          ),
        ),
      ),
    );
  }
}
