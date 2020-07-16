import Flutter
import UIKit
import SkyWay
import AVFoundation

public class SwiftFlutterIosWebrtcKitPlugin: NSObject {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: FlutterPluginChannelType.method.name,
                                                 binaryMessenger: registrar.messenger())
        let plugin = SwiftFlutterIosWebrtcKitPlugin(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(plugin, channel: methodChannel)
        registrar.register(plugin, withId: FlutterPluginChannelType.remoteView.name)
        registrar.register(plugin, withId: FlutterPluginChannelType.localView.name)
    }

    init(messenger: FlutterBinaryMessenger) {
        self.skyWayCenter = SkyWayCenter(eventChannel: FlutterEventChannel(name: FlutterPluginChannelType.event.name,
                                                                           binaryMessenger: messenger))
        super.init()
    }

    private let skyWayCenter: SkyWayCenter?

    // MARK: - method channel

    private func connect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.skyWayCenter?.connect(completion: { (peerId, errorMessage) in
            if let errorMessage = errorMessage {
                result(FlutterError(code: "method channel connect",
                                    message: errorMessage,
                                    details: nil))
                return
            }
            result(peerId)
        })
    }

    private func startCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let channelId = args["rtcChannelId"] as? String,
            let name = args["callerName"] as? String,
            let peerId = args["targetPeerId"] as? String else {
                result(FlutterError(code: "InvalidArguments startCall",
                                    message: nil,
                                    details: nil))
                return
        }

        self.skyWayCenter?.startCall(channelId: channelId,
                                     callerName: name,
                                     targetPeerId: peerId,
                                     completion: { (error) in
            result(error)
        })
    }

    private func endCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.skyWayCenter?.endCall()
        result(nil)
    }

    private func acceptedIncomingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.skyWayCenter?.acceptedIncomingCall()
        result(nil)
    }

    private func connectiblePeerIds(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.skyWayCenter?.connectiblePeerIds { (peerIds, error) in
            if let error = error {
                result(FlutterError(code: "method channel connectiblePeerIds",
                                    message: error.message ?? "no message",
                                    details: error.details ?? "no details"))
                return
            }

            result(peerIds)
        }
    }

    private func clearPeerIds(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.skyWayCenter?.clearPeerIds()
        result(nil)
    }

    private func enableVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        checkPermission(type: .video, call: call, result: result)
    }

    private func enableAudio(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        checkPermission(type: .audio, call: call, result: result)
    }

    private func checkPermission(type: AVMediaType, call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch AVCaptureDevice.authorizationStatus(for: type) {
        case .authorized:
            result(nil)
        case .denied:
            result(FlutterError(code: "checkPermission denied \(type.rawValue)",
                message: nil,
                details: nil))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: type) { check in
                print("get \(type.rawValue) permission: \(check)")
                result(nil)
            }
        case .restricted:
            result(FlutterError(code: "checkPermission restricted \(type.rawValue)",
                message: nil,
                details: nil))
        @unknown default:
            result(FlutterError(code: "checkPermission unknown \(type.rawValue)",
                message: nil,
                details: nil))
            break
        }
    }
}

extension SwiftFlutterIosWebrtcKitPlugin: FlutterPlugin {

    private enum MethodChannel: String {
        case connect
        case startCall
        case endCall
        case acceptedIncomingCall
        case connectiblePeerIds
        case clearPeerIds
        case enableVideo
        case enableAudio
    }

    // MARK: - FlutterPlugin（method channel）

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = MethodChannel(rawValue: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        switch method {
            case .connect:
                return connect(call, result: result)
            case .startCall:
                return startCall(call, result: result)
            case .endCall:
                return endCall(call, result: result)
            case .acceptedIncomingCall:
                return acceptedIncomingCall(call, result: result)
            case .connectiblePeerIds:
                return connectiblePeerIds(call, result: result)
            case .clearPeerIds:
                return clearPeerIds(call, result: result)
            case .enableVideo:
                return enableVideo(call, result: result)
            case .enableAudio:
                return enableAudio(call, result: result)
        }
    }
}

extension SwiftFlutterIosWebrtcKitPlugin: FlutterPlatformViewFactory {

    private class FlutterSkyWayPlatformView: NSObject, FlutterPlatformView {
        let platformView: UIView

        init(_ platformView: UIView) {
            self.platformView = platformView
            super.init()
        }

        func view() -> UIView {
            return platformView
        }
    }

    // MARK: - FlutterPlatformViewFactory

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {

       print("🎈 viewId: \(viewId), arguments: \(String(describing: args))")

       guard let skyWayCenter = self.skyWayCenter,
           let args = args as? [String: Any] else {
           let view = UIView(frame: frame)
           view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
           view.backgroundColor = .black
           return FlutterSkyWayPlatformView(view)
       }

       switch args["viewTypeName"] as? String {
       case FlutterPluginChannelType.remoteView.name:
           skyWayCenter.remoteStreamView.frame = frame
           skyWayCenter.remoteStreamView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
           skyWayCenter.remoteStreamView.backgroundColor = .black
           return FlutterSkyWayPlatformView(skyWayCenter.remoteStreamView)
       case FlutterPluginChannelType.localView.name:
           skyWayCenter.localStreamView.frame = frame
           skyWayCenter.localStreamView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
           skyWayCenter.localStreamView.backgroundColor = .black
           return FlutterSkyWayPlatformView(skyWayCenter.localStreamView)
       default:
           return FlutterSkyWayPlatformView(UIView(frame: .zero))
       }
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
