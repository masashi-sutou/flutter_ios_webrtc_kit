import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ios_webrtc_kit/channel_type.dart';

typedef IncomingAction = void Function(
  String rtcChannelId,
  String callerPeerId,
  String callerName,
);

class FlutterSkyWay {
  final MethodChannel _channel = MethodChannel(ChannelType.method.name);
  final String peerId;

  IncomingAction onIncomingCall;
  ValueChanged<String> onCanceledOutgoingCall;
  ValueChanged<String> onConnectedCall;
  ValueChanged<String> onDisconnectedCall;
  StreamSubscription<dynamic> _eventSubscription;

  FlutterSkyWay({
    @required this.peerId,
  }) {
    _eventSubscription = EventChannel(
      ChannelType.event.name,
    ).receiveBroadcastStream().listen(
          _eventListener,
          onError: _errorListener,
        );
  }

  Future<void> dispose() async {
    print('🎈 dispose');
    await _eventSubscription?.cancel();
    await clearPeerIds();
  }

  /// event channel

  void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'onIncomingCall':
        print('🎈 onIncomingCall($onIncomingCall): $map');
        if (onIncomingCall == null) {
          return;
        }

        onIncomingCall(
          map['rtcChannelId'],
          map['callerPeerId'],
          map['callerName'],
        );
        break;
      case 'onCanceledOutgoingCall':
        print('🎈 onCanceledOutgoingCall($onCanceledOutgoingCall): $map');
        if (onCanceledOutgoingCall == null) {
          return;
        }

        onCanceledOutgoingCall(
          map['targetPeerId'],
        );
        break;
      case 'onConnectedCall':
        print('🎈 onConnectedCall($onConnectedCall): $map');
        if (onConnectedCall == null) {
          return;
        }

        onConnectedCall(
          map['targetPeerId'],
        );
        break;
      case 'onDisconnectedCall':
        print('🎈 onDisconnectedCall($onDisconnectedCall): $map');
        if (onDisconnectedCall == null) {
          return;
        }

        onDisconnectedCall(
          map['targetPeerId'],
        );
        break;
    }
  }

  void _errorListener(Object obj) {
    print('🎈 onError: $obj');
  }

  /// method channel

  Future<void> startCall({
    @required String rtcChannelId,
    @required String callerName,
    @required String targetPeerId,
  }) async {
    print('🎈 startCall: $callerName, $callerName, $targetPeerId');
    return await _channel.invokeMethod('startCall', {
      'rtcChannelId': rtcChannelId,
      'callerName': callerName,
      'targetPeerId': targetPeerId,
    });
  }

  Future<void> endCall() async {
    print('🎈 endCall');
    return await _channel.invokeMethod('endCall');
  }

  Future<void> acceptedIncomingCall() async {
    print('🎈 acceptedIncomingCall');
    return await _channel.invokeMethod('acceptedIncomingCall');
  }

  Future<List<String>> connectiblePeerIds() async {
    print('🎈 connectiblePeerIds');
    final ids = await _channel.invokeMethod('connectiblePeerIds');
    return (ids as List)?.cast<String>() ?? [];
  }

  Future<void> clearPeerIds() async {
    print('🎈 clearPeerIds');
    await _channel.invokeMethod('clearPeerIds');
  }

  Future<void> enableVideo() async {
    print('🎈 enableVideo');
    await _channel.invokeMethod('enableVideo');
  }

  Future<void> enableAudio() async {
    print('🎈 enableAudio');
    await _channel.invokeMethod('enableAudio');
  }
}
