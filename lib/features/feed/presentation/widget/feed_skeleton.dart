import 'package:flutter/material.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';

/// Marcadores de posición con brillo animado mientras carga el Feed.
class FeedSkeleton extends StatefulWidget {
  final int count;
  const FeedSkeleton({super.key, this.count = 2});

  @override
  State<FeedSkeleton> createState() => _FeedSkeletonState();
}

class _FeedSkeletonState extends State<FeedSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({double? width, required double height, double radius = 8, BoxShape shape = BoxShape.rectangle}) {
    final base = FeedStyle.hairline;
    final highlight = base.withValues(alpha: 0.32);
    final v = _controller.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + 3 * v, 0),
          end: Alignment(-0.5 + 3 * v, 0),
          colors: [base, highlight, base],
        ),
      ),
    );
  }

  Widget _post() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _box(width: 38, height: 38, shape: BoxShape.circle),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_box(width: 120, height: 12), const SizedBox(height: 6), _box(width: 70, height: 10)],
                ),
              ],
            ),
          ),
          AspectRatio(aspectRatio: 4 / 5, child: _box(height: double.infinity, radius: 0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_box(width: 90, height: 14), const SizedBox(height: 10), _box(height: 12), const SizedBox(height: 6), _box(width: 200, height: 12)],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Column(children: List.generate(widget.count, (_) => _post())),
    );
  }
}
