//
//  WebRTCService.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/7.
//

import WebRTC
import Foundation

typealias WebRTCServiceResultHandler = (_ result: WebRTCServiceResult<RTCSessionDescription>) -> Void

class WebRTCServiceError: Error {
    var code: Int = 0
    var domain: String?
    var userInfo: [String: String]?
    
    init(code: Int, domain: String? = nil, userInfo: [String: String]? = nil) {
        self.code = code
        self.domain = domain
        self.userInfo = userInfo
    }
}

enum WebRTCServiceResult<T> {
    case success(T)
    case failure(Error)
}

protocol WebRTCServiceDelegate: NSObjectProtocol {
    func didGenerateCandidate(service: WebRTCService, iceCandidate: RTCIceCandidate)
    func didIceConnectionStateChanged(service: WebRTCService, iceConnectionState: RTCIceConnectionState)
    func didOpenDataChannel(service: WebRTCService)
    func didReceiveData(service: WebRTCService, data: Data?)
    func didReceiveMessage(service: WebRTCService, message: String?)
    func didConnectWebRTC(service: WebRTCService)
    func didDisconnectWebRTC(service: WebRTCService)
    func didAdd(service: WebRTCService, stream: RTCMediaStream)
}

class WebRTCService: NSObject {
    private lazy var peerConnectionFactory: RTCPeerConnectionFactory = {
        let peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(), decoderFactory: RTCDefaultVideoDecoderFactory())
        return peerConnectionFactory
    }()
    
    private var peerConnection: RTCPeerConnection?
    
    private lazy var mediaConstraints: RTCMediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    
    lazy var localVideoSource: CustomVideoSource = {
        let localVideoSource = self.peerConnectionFactory.videoSource()
        let forwardVideoSource = CustomVideoSource(rtcVideoSource: localVideoSource)
        return forwardVideoSource
    }()
    
    private lazy var localVideoTrack: RTCVideoTrack = {
        let localVideoTrack = self.peerConnectionFactory.videoTrack(with: self.localVideoSource.rtcVideoSource, trackId: "com.zoey.localVideoTrack")
        return localVideoTrack
    }()
    
    private lazy var localAudioTrack: RTCAudioTrack = {
        let audioSource = self.peerConnectionFactory.audioSource(with: self.mediaConstraints)
        let localAudioTrack = self.peerConnectionFactory.audioTrack(with: audioSource, trackId: "com.zoey.localAudioTrack")
        return localAudioTrack
    }()
    
    private var peerConnectQueue: DispatchQueue = DispatchQueue(label: "com.piaojin.peerConnectQueue")
    
    private var remoteVideoTrack: RTCVideoTrack?
    
    private var remoteAudioTrack: RTCAudioTrack?
    
    private var localDataChannel: RTCDataChannel?
    
    private var remoteDataChannel: RTCDataChannel?
    
    weak var delegate: WebRTCServiceDelegate?
    
    public private(set) var isConnected: Bool = false {
        didSet {
            self.didChangeConnectState(isConnected)
        }
    }
}

// MARK: function
extension WebRTCService {
    private func initWebRTCIfNeeded() {
        if peerConnection == nil {
            peerConnection = createPeerConnection()
            peerConnection?.add(localVideoTrack, streamIds: ["localVideoTrack"])
            peerConnection?.add(localAudioTrack, streamIds: ["localAudioTrack"])
        }
        
        if localDataChannel == nil {
            let dataChannelConfig = RTCDataChannelConfiguration()
            dataChannelConfig.channelId = 0
            localDataChannel = peerConnection?.dataChannel(forLabel: "localDataChannel", configuration: dataChannelConfig)
            localDataChannel?.delegate = self
        }
    }
    
    private func createPeerConnection() -> RTCPeerConnection {
        let rtcConf = RTCConfiguration()
        rtcConf.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let peerConnection = self.peerConnectionFactory.peerConnection(with: rtcConf, constraints: self.mediaConstraints, delegate: self)
        return peerConnection
    }
    
    func addLocalRenderer(_ render: RTCVideoRenderer) {
        self.localVideoTrack.add(render)
    }
    
    func removeLocalRenderer(_ render: RTCVideoRenderer) {
        self.localVideoTrack.remove(render)
    }
    
    func addRemoteRenderer(_ render: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(render)
    }
    
    func removeRemoteRenderer(_ render: RTCVideoRenderer) {
        self.remoteVideoTrack?.remove(render)
    }
}

// MARK: Connect
extension WebRTCService {
    func connect(_ completionHandler: WebRTCServiceResultHandler?) {
        peerConnectQueue.async { [weak self] in
            guard let `self` = self else {
                completionHandler?(WebRTCServiceResult<RTCSessionDescription>.failure(WebRTCServiceError(code: 0, domain: "`self` is nil", userInfo: nil)))
                return
            }
            
            self.initWebRTCIfNeeded()
            self.makeOffer(completionHandler)
        }
    }
    
    func disconnect() {
        isConnected = false
    }
    
    private func didChangeConnectState(_ isConnected: Bool) {
        peerConnectQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            if isConnected {
                self.delegate?.didConnectWebRTC(service: self)
            } else {
                if self.peerConnection?.connectionState == .connected {
                    self.peerConnection?.close()
                    self.peerConnection = nil
                    self.delegate?.didDisconnectWebRTC(service: self)
                }
            }
        }
    }
}

// MARK: Signaling
extension WebRTCService {
    func receiveOffer(offerSDP: RTCSessionDescription, createAnswerHandler: WebRTCServiceResultHandler?) {
        print("Receive remote offerSDP")
        initWebRTCIfNeeded()
        peerConnection?.setRemoteDescription(offerSDP) { [weak self] error in
            if let error = error {
                print("Set remote SDP faild")
                createAnswerHandler?(WebRTCServiceResult<RTCSessionDescription>.failure(error))
            } else {
                print("Set remote SDP successfully")
                self?.makeAnswer(createAnswerHandler)
            }
        }
    }
    
    func receiveAnswer(answerSDP: RTCSessionDescription) {
        peerConnection?.setRemoteDescription(answerSDP) { error in
            if let error = error {
                print("Set remote SDP faild: \(error)")
            } else {
                print("Set remote SDP successfully")
            }
        }
    }
    
    func makeOffer(_ completionHandler: WebRTCServiceResultHandler?) {
        peerConnection?.offer(for: self.mediaConstraints) { (sdp, err) in
            if let error = err {
                print("Make offer faild: \(error)")
                completionHandler?(WebRTCServiceResult<RTCSessionDescription>.failure(error))
                return
            }
            
            if let offerSDP = sdp {
                print("Get sdp and create local sdp")
                self.peerConnection?.setLocalDescription(offerSDP, completionHandler: { (err) in
                    if let error = err {
                        print("Set local offer sdp faild: \(error)")
                        completionHandler?(WebRTCServiceResult<RTCSessionDescription>.failure(error))
                        return
                    }
                    print("succeed to set local offer SDP")
                    completionHandler?(WebRTCServiceResult<RTCSessionDescription>.success(offerSDP))
                })
            } else {
                print("Didn't get sdp")
                completionHandler?(WebRTCServiceResult<RTCSessionDescription>.failure(WebRTCServiceError(code: 0, domain: "Didn't get sdp", userInfo: nil)))
            }
        }
    }
    
    func makeAnswer(_ completionHandler: WebRTCServiceResultHandler?) {
        peerConnection?.answer(for: self.mediaConstraints) { [weak self] answerSDP, error in
            if let error = error {
                print("Make answer faild: \(error)")
                completionHandler?(WebRTCServiceResult<RTCSessionDescription>.failure(error))
                return
            }
            
            guard let answerSDP = answerSDP else {
                print("Create local answerSDP faild")
                completionHandler?(WebRTCServiceResult<RTCSessionDescription>.failure(WebRTCServiceError(code: 0, domain: "Create local answerSDP faild", userInfo: nil)))
                return
            }
            
            self?.peerConnection?.setLocalDescription(answerSDP) { error in
                if let error = error {
                    print("Set local answer faild: \(error)")
                    completionHandler?(WebRTCServiceResult<RTCSessionDescription>.failure(error))
                    return
                }
                
                print("Set local answer successfully")
                completionHandler?(WebRTCServiceResult<RTCSessionDescription>.success(answerSDP))
            }
        }
    }
    
    func receiveCandidate(candidate: RTCIceCandidate) {
        peerConnection?.add(candidate)
    }
    
    func sendMessge(message: String) {
        if self.remoteDataChannel?.readyState == .open {
            if let message = message.data(using: .utf8) {
                let buffer = RTCDataBuffer(data: message, isBinary: false)
                self.remoteDataChannel?.sendData(buffer)
            }
        } else {
            print("Remote data channel is not ready")
        }
    }
    
    func sendData(data: Data) {
        if remoteDataChannel?.readyState == .open {
            let buffer = RTCDataBuffer(data: data, isBinary: true)
            remoteDataChannel?.sendData(buffer)
        } else {
            print("Remote data channel is not ready")
        }
    }
}

// MARK: RTCPeerConnectionDelegate
extension WebRTCService: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        var state = ""
        switch stateChanged {
            case .stable:
                state = "stable"
            case .closed:
                state = "closed"
            case .haveLocalOffer:
                state = "haveLocalOffer"
            case .haveLocalPrAnswer:
                state = "haveLocalPrAnswer"
            case .haveRemoteOffer:
                state = "haveRemoteOffer"
            case .haveRemotePrAnswer:
                state = "haveRemotePrAnswer"
        @unknown default:
            state = "@unknown"
        }
        print("Did change signaling state to: \(state)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Get remote stream")
        if let track = stream.videoTracks.first {
            self.remoteVideoTrack = track
            print("Set remote video track successfully")
        } else {
            print("Set remote video track faild")
        }
        
        if let audioTrack = stream.audioTracks.first{
            print("Set remote audio track successfully")
            self.remoteAudioTrack = audioTrack
            audioTrack.source.volume = 8
        } else {
            print("Set remote audio track faild")
        }
        
        self.delegate?.didAdd(service: self, stream: stream)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Did remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("Ice didChange newState \(newState)")
        switch newState {
        case .connected:
            self.isConnected = true
        case .disconnected, .closed:
            self.isConnected = false
        default:
            break
        }
        
        self.delegate?.didIceConnectionStateChanged(service: self, iceConnectionState: newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.didGenerateCandidate(service: self, iceCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("Did remove candidates")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        remoteDataChannel = dataChannel
        remoteDataChannel?.delegate = self
        delegate?.didOpenDataChannel(service: self)
    }
}

// MARK: RTCDataChannelDelegate
extension WebRTCService: RTCDataChannelDelegate {
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if buffer.isBinary {
            self.delegate?.didReceiveData(service: self, data: buffer.data)
        } else {
            self.delegate?.didReceiveMessage(service: self, message: String(data: buffer.data, encoding: .utf8))
        }
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        var state = ""
        switch dataChannel.readyState {
        case .closed:
            state = "closed"
            if dataChannel.channelId == localDataChannel?.channelId ?? -1 {
                localDataChannel?.close()
                localDataChannel = nil
            } else if dataChannel.channelId == remoteDataChannel?.channelId ?? -1 {
                remoteDataChannel?.close()
                remoteDataChannel = nil
            }
        case .closing:
            state = "closing"
        case .connecting:
            state = "connecting"
        case .open:
            state = "open"
        @unknown default:
            state = "@unknown"
        }
        
        print("Did change data channel state to: \(state)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        
    }
}
