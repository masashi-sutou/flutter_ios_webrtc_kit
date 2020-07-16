import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ios_voip_kit/call_state_type.dart';
import 'package:flutter_ios_voip_kit/flutter_ios_voip_kit.dart';
import 'package:flutter_ios_webrtc_kit/flutter_ios_webrtc_kit.dart';
import 'package:flutter_ios_webrtc_kit/flutter_sky_way.dart';
import 'package:flutter_ios_webrtc_kit_example/outgoing_call_page.dart';
import 'package:flutter_ios_webrtc_kit_example/video_talk_page.dart';
import 'package:uuid/uuid.dart';

class EntrancePage extends StatefulWidget {
  @override
  _EntrancePageState createState() => _EntrancePageState();
}

class _EntrancePageState extends State<EntrancePage> {
  final voIPKit = FlutterIOSVoIPKit.instance;
  FlutterSkyWay skyWay;
  final buttonSetupWebRTCText = 'Setup SkyWay SDK';
  Timer timeOutTimer;

  @override
  void initState() {
    super.initState();

    voIPKit.onDidRejectIncomingCall = (
      String uuid,
      String callerId,
    ) {
      print('🎈 EntrancePage.onDidRejectIncomingCall: $uuid, $callerId');
      _clearIncomingCallback();
    };

    voIPKit.onDidAcceptIncomingCall = (
      String uuid,
      String callerId,
    ) async {
      print('🎈 EntrancePage.onDidAcceptIncomingCall: $uuid, $callerId');
      await voIPKit.acceptIncomingCall(callerState: CallStateType.calling);
      await skyWay.acceptedIncomingCall();
    };

    _showRequestAuthLocalNotification();
  }

  void _showRequestAuthLocalNotification() async {
    await voIPKit.requestAuthLocalNotification();
  }

  void _timeOut({
    int seconds = 15,
  }) async {
    timeOutTimer = Timer(Duration(seconds: seconds), () async {
      print('🎈 EntrancePage.timeOut: $seconds');
      final incomingCallerName = await voIPKit.getIncomingCallerName();
      voIPKit.unansweredIncomingCall(
        skipLocalNotification: false,
        missedCallTitle: '📞 Missed call',
        missedCallBody: 'There was a call from $incomingCallerName',
      );
    });
  }

  @override
  void dispose() {
    print('🎈 EntrancePage.dispose');
    voIPKit.dispose();
    skyWay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC Example'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(18.0),
          child: Text(
            '📱 To try out the example app, you need two iPhones with iOS 10 or later. \n\nOne device is an outgoing call, and the other is waiting for an incoming call on this screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.5,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: skyWay != null
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green,
              icon: const Icon(Icons.phone),
              label: const Text('Show PeerId'),
              onPressed: () {
                _showConnectiblePeerIds();
              },
            )
          : FloatingActionButton.extended(
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.settings),
              label: Text(buttonSetupWebRTCText),
              onPressed: () {
                _connect();
              },
            ),
    );
  }

  /// Method channel

  Future<void> _connect() async {
    try {
      skyWay = await FlutterWebRTCKit.connect();
      skyWay.onIncomingCall = _onIncomingCall;
      setState(() {});
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  void _showConnectiblePeerIds() async {
    final connectiblePeerIds = await skyWay.connectiblePeerIds();
    if (connectiblePeerIds?.isEmpty ?? true) {
      return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Not found peerID'),
          content: Text(
            'Please launch ths example app on another ios device, and tap to $buttonSetupWebRTCText',
          ),
          actions: [
            FlatButton(
              textColor: Colors.grey,
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
          ],
        ),
      );
    }

    final actions = List.generate(connectiblePeerIds.length, (i) {
      final id = connectiblePeerIds[i];
      return FlatButton(
        textColor: Colors.green,
        child: Text('📞 $id'),
        onPressed: () async {
          await skyWay.enableAudio();
          await skyWay.enableVideo();
          Navigator.pop(context, id);
        },
      );
    });

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Call the tapped PeerID'),
        actions: actions
          ..add(
            FlatButton(
              textColor: Colors.grey,
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
          ),
      ),
    ).then<void>((v) {
      if (v == null) {
        return;
      }
      _startCall(v as String);
    });
  }

  void _startCall(String targetPeerId) async {
    print('🎈 EntrancePage._startCall: $targetPeerId');
    final uuid = Uuid().v4();

    await voIPKit.startCall(
      uuid: uuid,
      targetName: targetPeerId,
    );

    await skyWay.startCall(
      rtcChannelId: uuid,
      callerName: 'Bob',
      targetPeerId: targetPeerId,
    );

    Navigator.pushNamed(
      context,
      OutgoingCallPage.routeName,
      arguments: skyWay,
    );
  }

  /// Event channel

  void _onIncomingCall(
    String uuid,
    String callerPeerId,
    String callerName,
  ) async {
    print(
      '🎈 EntrancePage._onIncomingCall: $uuid, $callerPeerId, $callerName',
    );
    await voIPKit.testIncomingCall(
      uuid: uuid,
      callerId: callerPeerId,
      callerName: callerName,
    );

    skyWay.onCanceledOutgoingCall = _onCanceledOutgoingCall;
    skyWay.onConnectedCall = _onConnectedCall;
    _timeOut();
  }

  void _onCanceledOutgoingCall(String targetPeerId) {
    print('🎈 EntrancePage._onCanceledOutgoingCall: $targetPeerId');
    if (targetPeerId == null) {
      // Your OutgoingCall
      return;
    }

    voIPKit.unansweredIncomingCall(
      skipLocalNotification: true,
      missedCallTitle: null,
      missedCallBody: null,
    );
    _clearIncomingCallback();
  }

  void _onConnectedCall(String targetPeerId) {
    print('🎈 EntrancePage._onConnectedCall: $targetPeerId');
    _clearIncomingCallback();
    Navigator.pushNamed(
      context,
      VideoTalkPage.routeName,
      arguments: skyWay,
    );
  }

  void _clearIncomingCallback() {
    skyWay.onCanceledOutgoingCall = null;
    skyWay.onConnectedCall = null;
    timeOutTimer?.cancel();
  }
}
