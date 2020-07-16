import 'package:flutter/material.dart';
import 'package:flutter_ios_voip_kit/flutter_ios_voip_kit.dart';
import 'package:flutter_ios_webrtc_kit/flutter_sky_way.dart';
import 'package:flutter_ios_webrtc_kit_example/video_talk_page.dart';

class OutgoingCallPage extends StatefulWidget {
  static const routeName = '/outgoing_call';
  final FlutterSkyWay skyWay;

  const OutgoingCallPage({
    @required this.skyWay,
  });

  @override
  _OutgoingCallPageState createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage> {
  final voIPKit = FlutterIOSVoIPKit.instance;

  @override
  void initState() {
    super.initState();

    widget.skyWay.onConnectedCall = (String targetPeerId) {
      print('🎈 OutgoingCallPage.onConnectedCall: $targetPeerId');
      Navigator.pushReplacementNamed(
        context,
        VideoTalkPage.routeName,
        arguments: widget.skyWay,
      );
    };
  }

  @override
  void dispose() {
    print('🎈 OutgoingCallPage.dispose');
    widget.skyWay.onConnectedCall = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.notifications_active,
              color: Colors.green,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'outgoing call to another device',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _endCall();
        },
        backgroundColor: Colors.red,
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _endCall() async {
    print('🎈 OutgoingCallPage._endCall');
    await widget.skyWay.endCall();
    await voIPKit.endCall();
    Navigator.pop(context);
  }
}
