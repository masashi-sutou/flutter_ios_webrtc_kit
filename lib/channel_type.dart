enum ChannelType {
  method,
  event,
  eventPush,
  remoteView,
  localView,
}

extension ChannelKeyTypeEx on ChannelType {
  String get name {
    switch (this) {
      case ChannelType.method:
        return 'flutter_ios_webrtc_kit';
      case ChannelType.event:
        return 'flutter_ios_webrtc_kit/event';
      case ChannelType.remoteView:
        return 'flutter_ios_webrtc_kit/video_remote_view';
      case ChannelType.localView:
        return 'flutter_ios_webrtc_kit/video_local_view';
      default:
        return null;
    }
  }
}
