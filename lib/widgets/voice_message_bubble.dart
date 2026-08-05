import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/colors.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String? audioUrl;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    if (widget.audioUrl == null) {
      setState(() => _isError = true);
      return;
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (widget.audioUrl == null) return;

    if (_isError) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero) {
          setState(() => _isLoading = true);
          debugPrint('VoiceMessageBubble playing URL: ${widget.audioUrl}');
          await _audioPlayer.play(UrlSource(widget.audioUrl!));
          setState(() => _isLoading = false);
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Audio playback error: $e');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioUrl == null || _isError) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 20),
          SizedBox(width: 8),
          Text('Voice message unavailable'),
        ],
      );
    }

    final displayDuration =
        _position.inMilliseconds > 0 ? _position : _duration;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: widget.isMe
                  ? Colors.white.withOpacity(0.3)
                  : AspireColors.primary.withOpacity(0.1),
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            widget.isMe ? Colors.white : AspireColors.primary,
                      ))
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 20,
                      color: widget.isMe ? Colors.white : AspireColors.primary,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor:
                    widget.isMe ? Colors.white : AspireColors.primary,
                inactiveTrackColor: widget.isMe
                    ? Colors.white.withOpacity(0.3)
                    : AspireColors.primary.withOpacity(0.2),
                thumbColor: widget.isMe ? Colors.white : AspireColors.primary,
              ),
              child: Slider(
                min: 0,
                max: _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 100,
                value: _position.inMilliseconds > 0 &&
                        _position.inMilliseconds <= _duration.inMilliseconds
                    ? _position.inMilliseconds.toDouble()
                    : 0,
                onChanged: (value) async {
                  if (_duration.inMilliseconds > 0) {
                    final position = Duration(milliseconds: value.toInt());
                    await _audioPlayer.seek(position);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(displayDuration),
            style: TextStyle(
              fontSize: 12,
              color: widget.isMe ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
