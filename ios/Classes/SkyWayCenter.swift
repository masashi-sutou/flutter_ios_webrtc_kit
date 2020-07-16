//
//  SkyWayCenter.swift
//  flutter_ios_voip_kit
//
//  Created by 須藤将史 on 2020/07/16.
//

import Flutter
import UIKit
import SkyWay

final class SkyWayCenter: NSObject {

    private let peerOption = SKWPeerOption()
    private let peer: SKWPeer!
    private var dataConnection: SKWDataConnection?
    private var mediaConnection: SKWMediaConnection?
    private var localStream: SKWMediaStream?
    private var remoteStream: SKWMediaStream?

    let localStreamView = SKWVideo()
    let remoteStreamView = SKWVideo()

    // MARK: - event channel

    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?

    private enum EventChannel: String {
        case onIncomingCall
        case onCanceledOutgoingCall
        case onConnectedCall
        case onDisconnectedCall
    }

    private var isCallee: Bool = false

    init(eventChannel: FlutterEventChannel) {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            let plist = NSDictionary(contentsOfFile: path)
            self.peerOption.key = plist?["SKWApiKey"] as? String
            self.peerOption.domain = plist?["SKWDomain"] as? String ?? "localhost"
            self.peer = SKWPeer(options: self.peerOption)
        } else {
            self.peer = nil
        }

        self.eventChannel = eventChannel
        super.init()
        self.eventChannel.setStreamHandler(self)
    }

    private func setupMediaConnectionCallbacks(mediaConnection: SKWMediaConnection) {
        mediaConnection.on(.MEDIACONNECTION_EVENT_STREAM) { obj in
            if let msStream = obj as? SKWMediaStream {
                self.eventSink?(["event": EventChannel.onConnectedCall.rawValue,
                                 "targetPeerId": self.mediaConnection?.peer])
                self.remoteStream = msStream
                DispatchQueue.main.async {
                    self.remoteStream?.addVideoRenderer(self.remoteStreamView, track: 0)
                }
            }
        }

        mediaConnection.on(.MEDIACONNECTION_EVENT_CLOSE) { obj in
            if let _ = obj as? SKWMediaConnection {
                DispatchQueue.main.async {
                    self.eventSink?(["event": EventChannel.onDisconnectedCall.rawValue,
                                     "targetPeerId": self.mediaConnection?.peer])
                    self.remoteStream?.removeVideoRenderer(self.remoteStreamView,
                                                           track: 0)
                    self.remoteStream = nil
                    self.closeConnection()
                }
            }
        }

        mediaConnection.on(.MEDIACONNECTION_EVENT_ERROR) { obj in
            print("❌ MEDIACONNECTION_EVENT_ERROR: \(String(describing: obj))")
        }
    }

    private func setupDataConnectionCallbacks(dataConnection: SKWDataConnection?) {
        dataConnection?.on(.DATACONNECTION_EVENT_CLOSE) { obj in
            if (self.mediaConnection == nil && self.isCallee) {
                // Required for interruption: 発信側が発信キャンセルした場合ここに来る
                self.eventSink?(["event": EventChannel.onCanceledOutgoingCall.rawValue,
                                 "targetPeerId": self.dataConnection?.peer])
                self.dataConnection = nil
            }
        }

        dataConnection?.on(.DATACONNECTION_EVENT_ERROR) { obj in
            print("❌ DATACONNECTION_EVENT_ERROR: \(String(describing: obj))")
        }
    }

    private func setupStream(peer: SKWPeer?){
        guard let peer = peer else {
            return
        }

        SKWNavigator.initialize(peer)
        let constraints = SKWMediaConstraints()
        self.localStream = SKWNavigator.getUserMedia(constraints)
        self.localStream?.addVideoRenderer(self.localStreamView, track: 0)
    }

    private func closeConnection() {
        self.dataConnection?.close()
        self.mediaConnection?.close()
        self.dataConnection = nil
        self.mediaConnection = nil
        SKWNavigator.terminate()
    }

    // MARK: - method channel

    func connect(completion: @escaping (String?, String?) -> Void) {
        self.setupStream(peer: self.peer)

        self.peer.on(.PEER_EVENT_ERROR) { (_) in
            completion(nil,
                       "❌ Check Info.plist SKWApiKey, and get ApiKey https://webrtc.ecl.ntt.com/")
        }

        self.peer.on(.PEER_EVENT_OPEN) { obj in
            // 着信側のPeerIDが取得できる
            if let peerId = obj as? String {
                completion(peerId, nil)
            }
        }

        self.peer.on(.PEER_EVENT_CALL) { obj in
            // 接続に成功したら呼ばれる
            if let connection = obj as? SKWMediaConnection {
                self.setupMediaConnectionCallbacks(mediaConnection: connection)
                self.mediaConnection = connection
                connection.answer(self.localStream)
            }
        }

        self.peer.on(.PEER_EVENT_CONNECTION) { obj in
            // peer.connectで渡したpeerId（着信側）に接続要求を送信したら呼ばれる
            if let dataConnection = obj as? SKWDataConnection {
                self.isCallee = true
                self.eventSink?(["event": EventChannel.onIncomingCall.rawValue,
                                 "rtcChannelId": dataConnection.label,
                                 "callerPeerId": dataConnection.peer,
                                 "callerName": dataConnection.metadata])
                self.dataConnection = dataConnection
                self.setupDataConnectionCallbacks(dataConnection: dataConnection)
            }
        }
    }

    func startCall(channelId: String, callerName: String, targetPeerId: String, completion: @escaping (FlutterError?) -> Void) {
        guard mediaConnection == nil else {
            completion(FlutterError(code: "startCall",
                                    message: "mediaConnection not opend",
                                    details: nil))
            return
        }

        self.isCallee = false

        // 指定されたPeerIDに向けて発信（接続）する
        let options = SKWConnectOption()
        options.serialization = .SERIALIZATION_BINARY
        options.label = channelId
        options.metadata = callerName
        self.dataConnection = self.peer.connect(withId: targetPeerId,
                                                options: options)
        self.setupDataConnectionCallbacks(dataConnection: self.dataConnection)
        completion(nil)
    }

    func endCall() {
        self.closeConnection()
    }

    func acceptedIncomingCall() {
        guard let targetPeerId = self.dataConnection?.peer,
            let mediaConnection = self.peer.call(withId: targetPeerId,
                                                 stream: self.localStream,
                                                 options: SKWCallOption()) else {
            return
        }

        self.mediaConnection = mediaConnection
        self.setupMediaConnectionCallbacks(mediaConnection: mediaConnection)
    }

    func connectiblePeerIds(completion: @escaping ([String], FlutterError?) -> Void) {
        self.peer.listAllPeers() { peers in
            guard let peerIds = peers as? [String] else {
                completion([], FlutterError(code: "connectiblePeerIds", message: "type error", details: nil))
                return
            }

            let connectiblePeerIds = peerIds.filter { $0 != self.peer.identity }
            completion(connectiblePeerIds, nil)
        }
    }

    func clearPeerIds() {
        self.peer.destroy()
    }
}

extension SkyWayCenter: FlutterStreamHandler {

    // MARK: - FlutterStreamHandler（event channel）

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
