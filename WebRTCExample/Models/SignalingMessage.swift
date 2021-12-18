//
//  SignalingMessage.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/7.
//

import Foundation

enum SignalingMessageType: String, Codable {
    case offer = "offer"
    case answer = "answer"
    case unKnown = "unKnown"
    case candidate = "candidate"
}

struct SignalingMessage: Codable {
    let type: SignalingMessageType
    let sessionDescription: SDP?
    let candidate: Candidate?
}

struct SDP: Codable {
    let sdp: String
}

struct Candidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
}
