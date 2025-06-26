import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const String appId = 'f0d6eab006144baba40070fd28215756';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String token;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.token,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final RtcEngine _engine;
  int? remoteUid;
  bool muted = false;
  bool videoOff = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: appId));
      await _engine.enableVideo();
      await _engine.startPreview();

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onError: (errCode, errMsg) {
            debugPrint('Agora error: \$errCode - \$errMsg');
          },
          onUserJoined: (connection, uid, elapsed) {
            setState(() {
              remoteUid = uid;
            });
          },
          onUserOffline: (connection, uid, reason) {
            setState(() {
              remoteUid = null;
            });
          },
        ),
      );

      await _engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      debugPrint('Agora initialization failed: \$e');
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void _onToggleMute() {
    setState(() => muted = !muted);
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleVideo() {
    setState(() => videoOff = !videoOff);
    _engine.muteLocalVideoStream(videoOff);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: remoteUid),
                    connection: RtcConnection(channelId: widget.channelName),
                  ),
                )
              : const Center(child: Text("Waiting for user...")),
          Positioned(
            top: 20,
            left: 20,
            width: 120,
            height: 160,
            child: videoOff
                ? const ColoredBox(color: Colors.black)
                : AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(muted ? Icons.mic : Icons.mic_off),
                    onPressed: _onToggleMute,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.red),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(videoOff ? Icons.videocam : Icons.videocam_off),
                    onPressed: _onToggleVideo,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
