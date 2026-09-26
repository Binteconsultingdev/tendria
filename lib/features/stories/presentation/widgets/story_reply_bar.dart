import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper.dart';
import 'package:tendria/features/feed/presentation/widget/reaction_icon.dart';
import 'package:tendria/features/stories/data/story_interaction_repository.dart';

const List<String> _storyReactions = ['me_encanta', 'fuego', 'jaja', 'wow', 'triste', 'me_gusta'];

/// Barra inferior al ver la historia de otra persona: escribir una respuesta y reaccionar.
/// Al escribir se pausa la historia; al terminar se reanuda.
class StoryReplyBar extends StatefulWidget {
  final int storyId;
  final String? initialReaction;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const StoryReplyBar({
    super.key,
    required this.storyId,
    required this.initialReaction,
    required this.onPause,
    required this.onResume,
  });

  @override
  State<StoryReplyBar> createState() => _StoryReplyBarState();
}

class _StoryReplyBarState extends State<StoryReplyBar> with SingleTickerProviderStateMixin {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  final StoryInteractionRepository _repo = StoryInteractionRepository.instance;

  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  String? _reaction;
  String? _burstType;
  bool _showReactions = false;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _reaction = widget.initialReaction;
    _focus.addListener(() {
      if (_focus.hasFocus) {
        widget.onPause();
        setState(() => _showReactions = false);
      } else if (!_showReactions) {
        widget.onResume();
      }
    });
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _burst.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _react(String type) async {
    final previous = _reaction;
    final removing = _reaction == type;
    setState(() {
      _reaction = removing ? null : type;
      _showReactions = false;
      if (!removing) {
        _burstType = type;
        _burst.forward(from: 0);
      }
    });
    widget.onResume();
    try {
      removing ? await _repo.removeReaction(widget.storyId) : await _repo.react(widget.storyId, type);
    } catch (e) {
      if (mounted) setState(() => _reaction = previous);
      showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.reply(widget.storyId, value);
      if (!mounted) return;
      _text.clear();
      _focus.unfocus();
      setState(() => _sent = true);
      widget.onResume();
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _sent = false);
      });
    } catch (e) {
      showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final hasText = _text.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: _showReactions
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final type in _storyReactions)
                              GestureDetector(
                                onTap: () => _react(type),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 150),
                                  scale: _reaction == type ? 1.25 : 1.0,
                                  child: ReactionIcon(type: type, size: 40),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                      ),
                      alignment: Alignment.center,
                      child: _sent
                          ? Row(
                              children: [
                                const Icon(LucideIcons.checkCheck, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Enviado', style: GoogleFonts.rubik(color: Colors.white, fontSize: 14)),
                              ],
                            )
                          : TextField(
                              controller: _text,
                              focusNode: _focus,
                              maxLength: 1000,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              style: GoogleFonts.rubik(color: Colors.white, fontSize: 14.5),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                counterText: '',
                                isDense: true,
                                filled: false,
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Enviar mensaje...',
                                hintStyle: GoogleFonts.rubik(color: Colors.white.withValues(alpha: 0.65), fontSize: 14.5),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (hasText)
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, shape: BoxShape.circle),
                        child: _sending
                            ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(LucideIcons.arrowUp, color: Colors.white, size: 22),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        setState(() => _showReactions = !_showReactions);
                        _showReactions ? widget.onPause() : widget.onResume();
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.45))),
                        child: _reaction != null
                            ? ReactionIcon(type: _reaction!, size: 28)
                            : const Icon(LucideIcons.heart, color: Colors.white, size: 22),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Reacción que sube y se encoge hasta desaparecer (sin capas de opacidad, que en algunos teléfonos dibujan un rectángulo)
          if (_burstType != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (_, __) {
                    final t = _burst.value;
                    // crece rápido al inicio y se encoge en el último tramo
                    final scale = t < 0.2 ? t / 0.2 : (t > 0.7 ? (1 - t) / 0.3 : 1.0);
                    final size = 72 * scale;
                    return SizedBox(
                      height: 200,
                      child: Align(
                        alignment: Alignment(0, 1 - 2 * Curves.easeOut.transform(t)),
                        child: size < 2 ? const SizedBox.shrink() : ReactionIcon(type: _burstType!, size: size),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
