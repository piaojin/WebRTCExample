//
//  WebRTCContainerRenderView.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/9.
//

import WebRTC
import UIKit

class WebRTCContainerRenderView: UIView, RTCVideoViewDelegate {
    lazy var localRenderView: CustomVideoView = {
        let shader = CustomRTCDefaultShader()
        let localRenderView = CustomVideoView(frame: .zero, shader: shader)
//        let localRenderView = CustomVideoView(frame: .zero)
        localRenderView.translatesAutoresizingMaskIntoConstraints = false
        localRenderView.delegate = self
        return localRenderView
    }()
    
    lazy var remoteRenderView: CustomVideoView = {
        let remoteRenderView = CustomVideoView()
        remoteRenderView.translatesAutoresizingMaskIntoConstraints = false
        remoteRenderView.delegate = self
        return remoteRenderView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setUpView()
    }
    
    convenience init() {
        self.init(frame: .zero)
        setUpView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpView() {
        self.addSubview(remoteRenderView)
        remoteRenderView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        remoteRenderView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        remoteRenderView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        remoteRenderView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        self.addSubview(localRenderView)
        localRenderView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        localRenderView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        localRenderView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.3).isActive = true
        localRenderView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.3).isActive = true
    }
    
    private func updateUI() {
        
    }
    
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        updateUI()
    }
}
