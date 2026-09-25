import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

/// Video de una publicación. No descarga ni decodifica nada hasta que se toca para reproducir
/// (así un Feed con varios videos no gasta datos, memoria ni batería sin necesidad).
class PostVideoPlayer extends StatefulWidget {
  final String url;
  final VoidCallback? onDoubleTap;

  const PostVideoPlayer({super.key, required this.url, this.onDoubleTap});

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;
  bool _muted = false;

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });

    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      controller.addListener(_onTick);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTap() {
    final c = _controller;
    if (c == null) {
      _start();
      return;
    }
    c.value.isPlaying ? c.pause() : c.play();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final playing = ready && c.value.isPlaying;

    return GestureDetector(
      onTap: _onTap,
      onDoubleTap: widget.onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: ready
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  )
                : null,
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
          else if (_failed)
            const Center(child: Icon(LucideIcons.videoOff, size: 40, color: Colors.white54))
          else
            AnimatedOpacity(
              opacity: playing ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                ),
              ),
            ),
          if (ready) ...[
            Positioned(
              right: 12,
              bottom: 14,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                  child: Icon(_muted ? LucideIcons.volumeX : LucideIcons.volume2, color: Colors.white, size: 18),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: false,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
