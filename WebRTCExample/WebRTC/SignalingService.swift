//
//  SignalingService.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/7.
//

import WebRTC
import Starscream
import Foundation

protocol SignalingServiceDelegate: NSObjectProtocol {
    func websocketDidConnect(service: SignalingService)
    
    func websocketDidDisconnect(service: SignalingService, error: Error?)
    
    func websocketDidReceiveMessage(service: SignalingService, signalingMessage: SignalingMessage?)
    
    func websocketDidReceiveData(service: SignalingService, data: Data)
}

class SignalingService {
    private var socket: WebSocket?
    private var signalingAddress: String?
    
    var isConnected: Bool {
        return socket?.isConnected == true
    }
    
    weak var delegate: SignalingServiceDelegate?
    
    init(signalingAddress: String) {
        self.signalingAddress = signalingAddress
        setUpData()
    }
    
    private func setUpData() {
        if let signalingAddress = signalingAddress, let url = URL(string: signalingAddress) {
            socket = WebSocket(url: url)
            socket?.delegate = self
        } else {
            print("Init socket faild")
        }
    }
    
    func connect() {
        if socket == nil {
            setUpData()
        }
        
        if socket?.isConnected == false {
            socket?.connect()
        }
    }
    
    func sendSDP(sessionDescription: RTCSessionDescription) {
        var type: SignalingMessageType = .unKnown
        if sessionDescription.type == .offer {
            type = .offer
        }else if sessionDescription.type == .answer {
            type = .answer
        }
        
        let sdp = SDP(sdp: sessionDescription.sdp)
        let signalingMessage = SignalingMessage(type: type, sessionDescription: sdp, candidate: nil)
        
        do {
            try sendMessage(signalingMessage)
        } catch {
            print("sendSDP faild: \(error)")
        }
    }
    
    func sendCandidate(iceCandidate: RTCIceCandidate) {
        let candidate = Candidate(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid)
        let signalingMessage = SignalingMessage(type: .candidate, sessionDescription: nil, candidate: candidate)
        do {
            try sendMessage(signalingMessage)
        } catch {
            print("sendCandidate faild: \(error)")
        }
    }
    
    private func sendMessage(_ signalingMessage: SignalingMessage) throws {
        let data = try JSONEncoder().encode(signalingMessage)
        if let message = String(data: data, encoding: .utf8) {
            if self.socket?.isConnected == true {
                self.socket?.write(string: message)
            }
        }
    }
}

extension SignalingService: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        delegate?.websocketDidConnect(service: self)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        delegate?.websocketDidDisconnect(service: self, error: error)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        do {
            guard let data = text.data(using: .utf8) else {
                delegate?.websocketDidReceiveMessage(service: self, signalingMessage: nil)
                return
            }
            let signalingMessage = try JSONDecoder().decode(SignalingMessage.self, from: data)
            delegate?.websocketDidReceiveMessage(service: self, signalingMessage: signalingMessage)
        } catch {
            delegate?.websocketDidReceiveMessage(service: self, signalingMessage: nil)
            print("Decode SignalingMessage faild: \(error)")
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        delegate?.websocketDidReceiveData(service: self, data: data)
    }
}
