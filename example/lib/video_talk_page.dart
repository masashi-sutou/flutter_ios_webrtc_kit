import 'package:flutter/material.dart';
import 'package:flutter_ios_voip_kit/flutter_ios_voip_kit.dart';
import 'package:flutter_ios_webrtc_kit/flutter_ios_webrtc_kit.dart';
import 'package:flutter_ios_webrtc_kit/flutter_sky_way.dart';

class VideoTalkPage extends StatefulWidget {
  static const routeName = '/video_talk';
  final FlutterSkyWay skyWay;

  const VideoTalkPage({
    @required this.skyWay,
  });

  @override
  _VideoTalkPageState createState() => _VideoTalkPageState();
}

class _VideoTalkPageState extends State<VideoTalkPage> {
  final voIPKit = FlutterIOSVoIPKit.instance;

  @override
  void initState() {
    super.initState();

    voIPKit.callConnected();
    widget.skyWay.onDisconnectedCall = (String targetPeerId) {
      print('🎈 VideoTalkPage.onDisconnectedCall: $targetPeerId');
      Navigator.pop(context);
    };
  }

  @override
  void dispose() {
    print('🎈 VideoTalkPage.dispose');
    widget.skyWay.onDisconnectedCall = null;
    voIPKit.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              color: Colors.black,
              constraints: const BoxConstraints.expand(),
              child: FlutterWebRTCKit.remoteStreamView(),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 18, left: 18),
                child: Container(
                  color: Colors.black,
                  width: 120,
                  height: 180,
                  child: FlutterWebRTCKit.localStreamView(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await widget.skyWay.endCall();
        },
        backgroundColor: Colors.red,
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
        ),
      ),
    );
  }
}
