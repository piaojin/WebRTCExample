//
//  CustomVideoView.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/8.
//

import WebRTC
import Foundation

class CustomVideoView: RTCEAGLVideoView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
