import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayer extends StatefulWidget {
  final String videoUrl;
  const VideoPlayer({super.key, required this.videoUrl});

  @override
  // ignore: library_private_types_in_public_api
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  final double fixedWidth = 250;

  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    // ignore: deprecated_member_use
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        _initializeChewie();
        _startHideControlsTimer();
      });
  }

  void _initializeChewie() {
    setState(() {
      _chewieController?.dispose();
      _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: false,
          looping: true,
          zoomAndPan: true,
          showControls: _showControls,
          showControlsOnInitialize: false);
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showControls = false;
        _initializeChewie();
      });
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _initializeChewie();
    });

    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: SizedBox(
        width: fixedWidth,
        height: fixedWidth / _controller.value.aspectRatio,
        child: _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
