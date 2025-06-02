import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  static final _engine = createAgoraRtcEngine();

  static Future<void> init(String channelName) async {
    await _engine.initialize(
        RtcEngineContext(appId: 'f0d6eab006144baba40070fd28215756'));
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
        token: "",
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions());
  }

  static void leaveChannel() {
    _engine.leaveChannel();
  }
}
