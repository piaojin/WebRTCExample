//
//  CustomVideoCapturerService.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/8.
//

import WebRTC
import AVFoundation
import Foundation

enum CaptureFrame {
    case captureFramePreset352X288
    case captureFramePreset640X480
    case captureFramePreset960X540
    case captureFramePreset1280x720
}

class CustomVideoCapturerService {
    private weak var webRTCService: WebRTCService?
    private var cameraVideoCapturer: RTCCameraVideoCapturer
    
    init(webRTCService: WebRTCService) {
        self.webRTCService = webRTCService
        self.cameraVideoCapturer = RTCCameraVideoCapturer(delegate: webRTCService.localVideoSource)
        if let output = self.cameraVideoCapturer.captureSession.outputs.first as? AVCaptureVideoDataOutput {
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        }
    }
    
    func startCaptureLocalVideo(position: AVCaptureDevice.Position, frame: CaptureFrame, completeHandler: ((Error) -> Void)?) {
        
        if let device = findDeviceForPosition(position), let format = selectFormatForDevice(device, frame: frame) {
            let fps = selectFpsForFormat(format)
            cameraVideoCapturer.startCapture(with: device, format: format, fps: fps) { error in
                completeHandler?(error)
            }
        }
    }
    
    private func findDeviceForPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let captureDevices = RTCCameraVideoCapturer.captureDevices()
        
        if let device = captureDevices.first(where: { device in
            return device.position == position
        }) {
            return device
        }
        
        print("No suitable position found.")
        return nil
    }
    
    private func selectFormatForDevice(_ device: AVCaptureDevice, frame: CaptureFrame) -> AVCaptureDevice.Format? {
        let supportedFormats = RTCCameraVideoCapturer.supportedFormats(for: device)
        var targetWidth: Int32 = 0
        var targetHeight: Int32 = 0
        switch frame {
        case .captureFramePreset352X288:
            targetWidth = 352
            targetHeight = 288
        case .captureFramePreset640X480:
            targetWidth = 640
            targetHeight = 480
        case .captureFramePreset960X540:
            targetWidth = 960
            targetHeight = 540
        case .captureFramePreset1280x720:
            targetWidth = 1280
            targetHeight = 720
        }
        
        var selectedFormat: AVCaptureDevice.Format?
        var currentDiff = INT_MAX
        
        supportedFormats.forEach { format in
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height)
            if (diff < currentDiff) {
                selectedFormat = format
                currentDiff = diff
            }
        }
        
        if selectedFormat == nil {
            print("No suitable capture format found.")
        }
        return selectedFormat
    }
    
    private func selectFpsForFormat(_ format: AVCaptureDevice.Format) -> Int {
        var maxFramerate:Float64 = 0
        format.videoSupportedFrameRateRanges.forEach { fpsRange in
            if fpsRange.minFrameRate < 30 && fpsRange.maxFrameRate >= 30 {
                maxFramerate = 30;
            } else {
                maxFramerate = fmax(maxFramerate, fpsRange.maxFrameRate);
            }
        }
        return Int(maxFramerate)
    }
}
