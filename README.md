# flutter_ios_webrtc_kit

WebRTC(SkyWay) sample ios app with [flutter_ios_voip_kit](https://github.com/masashi-sutou/flutter_ios_voip_kit)

## Requirement

- iOS only, not support Android.
- iOS 10 or above.
- one-to-one call only, not support group call.

## try out example app

### 1. Get SkyWay API Key

- sign in https://webrtc.ecl.ntt.com/
- get SkyWay API Key.

### 2. Edit Info.plist

- edit `flutter_ios_webrtc_kit/example/ios/Runner/Info.plist` as below.

```
	<key>SKWApiKey</key>
	<string>Your SkyWay API Key</string>
```

### 3. Install example app to two iPhones

- you need two iPhones to try the example app.
- one is outgoing call device and the other is incoming call device.

select peerId | outgoing | incoming | talking
:-: | :-: | :-: | :-:
<img src=https://user-images.githubusercontent.com/6649643/87827901-c69cf680-c8b6-11ea-9b44-1621c94ede1d.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87827929-d61c3f80-c8b6-11ea-8f7b-92d2efcbc0e4.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87827937-dddbe400-c8b6-11ea-8926-777c9dce94ad.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87827944-e03e3e00-c8b6-11ea-83b5-a20c6280427f.png width=180/>

## Reference

- https://webrtc.ecl.ntt.com/
- https://webrtc.ecl.ntt.com/documents/ios-sdk.html
