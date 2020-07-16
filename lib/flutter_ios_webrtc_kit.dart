import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ios_webrtc_kit/channel_type.dart';
import 'package:flutter_ios_webrtc_kit/flutter_sky_way.dart';

class FlutterWebRTCKit {
  static final MethodChannel _channel = MethodChannel(ChannelType.method.name);

  static Future<FlutterSkyWay> connect() async {
    final peerId = await _channel.invokeMethod('connect');
    print('🎈 peerId: $peerId');
    return FlutterSkyWay(peerId: peerId);
  }

  static Widget remoteStreamView() {
    final viewType = ChannelType.remoteView;
    return UiKitView(
      viewType: viewType.name,
      creationParamsCodec: const StandardMessageCodec(),
      creationParams: <String, dynamic>{
        "viewTypeName": viewType.name,
      },
      onPlatformViewCreated: (id) {
        print('🎈 remoteStreamView created: id = $id');
      },
    );
  }

  /*
   * FIXME: Second time is not displayed
   */
  static Widget localStreamView() {
    final viewType = ChannelType.localView;
    return UiKitView(
      viewType: viewType.name,
      creationParamsCodec: const StandardMessageCodec(),
      creationParams: <String, dynamic>{
        "viewTypeName": viewType.name,
      },
      onPlatformViewCreated: (id) {
        print('🎈 localStreamView created: id = $id');
      },
    );
  }
}
