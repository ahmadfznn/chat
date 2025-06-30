import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  static final RtcEngine _engine = createAgoraRtcEngine();
  static const String _appId = 'f0d6eab006144baba40070fd28215756';

  static Future<void> init(String channelName, String token) async {
    try {
      await _engine.initialize(RtcEngineContext(appId: _appId));
      await _engine.enableVideo();
      await _engine.startPreview();
      await _engine.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      // ignore: avoid_print
      print("Agora init error: \$e");
    }
  }

  static void leaveChannel() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      // ignore: avoid_print
      print("Agora leave error: \$e");
    }
  }
}
