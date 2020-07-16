//
//  FlutterPluginChannelType.swift
//  flutter_ios_voip_kit
//
//  Created by 須藤将史 on 2020/07/16.
//

import Foundation

enum FlutterPluginChannelType {
    case method
    case event
    case remoteView
    case localView

    var name: String {
        switch self {
        case .method:
            return "flutter_ios_webrtc_kit"
        case .event:
            return "flutter_ios_webrtc_kit/event"
        case .remoteView:
            return "flutter_ios_webrtc_kit/video_remote_view"
        case .localView:
            return "flutter_ios_webrtc_kit/video_local_view"
        }
    }
}
