//
//  CustomVideoSource.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/8.
//

import WebRTC
import Foundation
import CoreVideo

class CustomVideoSource: NSObject, RTCVideoCapturerDelegate {
    
    var rtcVideoSource: RTCVideoSource
    
    private var orientation: UIInterfaceOrientation = .portrait
    
    var pixelBufferProcesser: ProcessPixelBufferProtocol?
    
    private var keyWindow: UIWindow? {
        // Get connected scenes
        return UIApplication.shared.connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
    init(rtcVideoSource: RTCVideoSource) {
        self.rtcVideoSource = rtcVideoSource
        super.init()
        self.setUpData()
    }
    
    private func setUpData() {
        DispatchQueue.main.async {
            self.orientation = self.keyWindow?.windowScene?.interfaceOrientation ?? .portrait
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func orientationDidChange(_ notification: Notification) {
        orientation = keyWindow?.windowScene?.interfaceOrientation ?? .portrait
    }
    
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        // Fix frame ortation for RTCVideoRotation_270
        let isFrontCamera = isUsingFrontCamera(capturer: capturer)
        let fixedFrame = RTCVideoFrame(buffer: frame.buffer, rotation: fixFrameRotation(statusBarOrientation: orientation, isUsingFrontCamera: isFrontCamera), timeStampNs: frame.timeStampNs)
        var videoFrame: RTCVideoFrame = frame
        
        if pixelBufferProcesser?.shouldProcessFrameBuffer() == true {
            var pixelBuffer: CVPixelBuffer?
            
            // Get original RTC pixelBuffer
            if let rtcCVPixelBuffer = fixedFrame.buffer as? RTCCVPixelBuffer {
                pixelBuffer = rtcCVPixelBuffer.pixelBuffer
            }
            
            // Process pixelBuffer. e.g. Add filter, effects
            if let originalRTCPixelBuffer = pixelBuffer, let reusltPixelBuffer = pixelBufferProcesser?.processBuffer(CustomVideoFrame(buffer: originalRTCPixelBuffer, rotation: convertVideoRotation(rotation: fixedFrame.rotation), timeStampNs: fixedFrame.timeStampNs)) {
                
                pixelBuffer = reusltPixelBuffer
                
                // Forward frame to RTCVideoSource
//                let processedPixelBuffer: RTCCVPixelBuffer = RTCCVPixelBuffer(pixelBuffer: reusltPixelBuffer)
//                videoFrame = RTCVideoFrame(buffer: processedPixelBuffer, rotation: fixedFrame.rotation, timeStampNs: fixedFrame.timeStampNs)
            }
            
            // Recreate videoFrame
            if let pixelBuffer = pixelBuffer {
                var rotation: RTCVideoRotation = fixedFrame.rotation;
                if rotation == RTCVideoRotation._270 {
                    rotation = RTCVideoRotation._0
                }
                let rtcCVPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
                videoFrame = RTCVideoFrame(buffer: rtcCVPixelBuffer, rotation: rotation, timeStampNs: fixedFrame.timeStampNs)
            }
        }
        
        rtcVideoSource.capturer(capturer, didCapture: videoFrame)
    }
    
    private func isUsingFrontCamera(capturer: RTCVideoCapturer) -> Bool {
        guard let cameraCapture = capturer as? RTCCameraVideoCapturer else {
            return false
        }
        
        if let deviceInput = cameraCapture.captureSession.inputs.first as? AVCaptureDeviceInput {
            return AVCaptureDevice.Position.front == deviceInput.device.position
        }
        return false
    }
    
    private func fixFrameRotation(statusBarOrientation: UIInterfaceOrientation, isUsingFrontCamera: Bool) -> RTCVideoRotation {
        var rotation: RTCVideoRotation = RTCVideoRotation._90
        switch statusBarOrientation {
        case .unknown:
            break
        case .portrait:
            rotation = RTCVideoRotation._90
        case .portraitUpsideDown:
            rotation = RTCVideoRotation._270
        case .landscapeLeft:
            rotation = isUsingFrontCamera ? RTCVideoRotation._0 : RTCVideoRotation._180
        case .landscapeRight:
            rotation = isUsingFrontCamera ? RTCVideoRotation._180 : RTCVideoRotation._0
        @unknown default:
            break
        }
        return rotation
    }
    
    private func convertVideoRotation(rotation: RTCVideoRotation) -> CustomVideoRotation {
        switch rotation {
        case ._0:
            return ._0
        case ._90:
            return ._90
        case ._180:
            return ._180
        case ._270:
            return ._270
        @unknown default:
            return ._90
        }
    }
}
