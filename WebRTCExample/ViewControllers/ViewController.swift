//
//  ViewController.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/7.
//

import Starscream
import WebRTC
import AVFoundation
import UIKit

class ViewController: UIViewController {

    private var renderView: WebRTCContainerRenderView = {
        let renderView = WebRTCContainerRenderView()
        renderView.translatesAutoresizingMaskIntoConstraints = false
        renderView.backgroundColor = .systemGreen
        return renderView
    }()
    
    private var makeOfferButton: UIButton = {
        let makeOfferButton = UIButton(type: .system)
        makeOfferButton.translatesAutoresizingMaskIntoConstraints = false
        makeOfferButton.setTitle("Make Offer", for: .normal)
        makeOfferButton.backgroundColor = .systemBlue
        makeOfferButton.setTitleColor(.white, for: .normal)
        return makeOfferButton
    }()
    
    private var hangUpButton: UIButton = {
        let hangUpButton = UIButton(type: .system)
        hangUpButton.translatesAutoresizingMaskIntoConstraints = false
        hangUpButton.setTitle("Hang Up", for: .normal)
        hangUpButton.backgroundColor = .systemBlue
        hangUpButton.setTitleColor(.white, for: .normal)
        return hangUpButton
    }()
    
    private var sendMessageButton: UIButton = {
        let sendMessageButton = UIButton(type: .system)
        sendMessageButton.translatesAutoresizingMaskIntoConstraints = false
        sendMessageButton.setTitle("Send", for: .normal)
        sendMessageButton.backgroundColor = .systemGreen
        sendMessageButton.setTitleColor(.white, for: .normal)
        return sendMessageButton
    }()
    
    private var messageLabel: UILabel = {
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        return messageLabel
    }()
    
    private var inputBox: UITextField = {
        let inputBox = UITextField()
        inputBox.translatesAutoresizingMaskIntoConstraints = false
        inputBox.layer.borderColor = UIColor.systemGreen.cgColor
        inputBox.layer.borderWidth = 1.0
        inputBox.font = UIFont.systemFont(ofSize: 23.0)
        return inputBox
    }()
    
    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 3
        stackView.backgroundColor = .clear
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private var stateLabel: UILabel = {
        let stateLabel = UILabel()
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        stateLabel.textColor = .systemRed
        stateLabel.text = "DisConnected"
        return stateLabel
    }()
    
    private var webRTCService: WebRTCService = WebRTCService()
    private var signalingService: SignalingService = SignalingService(signalingAddress: signalingAddress)
    private lazy var videoCapturerService: CustomVideoCapturerService = CustomVideoCapturerService(webRTCService: webRTCService)
    
    private var isConnected: Bool {
        return webRTCService.isConnected && signalingService.isConnected
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpView()
        setUpData()
    }
    
    private func setUpView() {
        self.view.backgroundColor = .white
        self.view.addSubview(inputBox)
        inputBox.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -6).isActive = true
        inputBox.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 3).isActive = true
        inputBox.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.75).isActive = true
        
        self.view.addSubview(sendMessageButton)
        sendMessageButton.leadingAnchor.constraint(equalTo: inputBox.trailingAnchor, constant: 3).isActive = true
        sendMessageButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -3).isActive = true
        sendMessageButton.centerYAnchor.constraint(equalTo: inputBox.centerYAnchor).isActive = true
        
        stackView.addArrangedSubview(makeOfferButton)
        stackView.addArrangedSubview(hangUpButton)
        self.view.addSubview(stackView)
        stackView.bottomAnchor.constraint(equalTo: sendMessageButton.topAnchor, constant: -10).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 3).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -3).isActive = true
        
        self.view.addSubview(messageLabel)
        messageLabel.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -10).isActive = true
        messageLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 3).isActive = true
        messageLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -3).isActive = true
        messageLabel.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        self.view.addSubview(renderView)
        renderView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        renderView.bottomAnchor.constraint(equalTo: messageLabel.topAnchor).isActive = true
        renderView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        renderView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        let statePromptLabel = UILabel()
        statePromptLabel.translatesAutoresizingMaskIntoConstraints = false
        statePromptLabel.textColor = .systemGreen
        statePromptLabel.text = "Connection State:"
        
        renderView.addSubview(statePromptLabel)
        statePromptLabel.topAnchor.constraint(equalTo: renderView.topAnchor, constant: 20).isActive = true
        statePromptLabel.leadingAnchor.constraint(equalTo: renderView.leadingAnchor, constant: 20).isActive = true
        
        renderView.addSubview(stateLabel)
        stateLabel.centerYAnchor.constraint(equalTo: statePromptLabel.centerYAnchor).isActive = true
        stateLabel.leadingAnchor.constraint(equalTo: statePromptLabel.trailingAnchor, constant: 6).isActive = true
    }
    
    private func setUpData() {
        messageLabel.text = "Receive Message:"
        
        webRTCService.delegate = self
        webRTCService.addLocalRenderer(renderView.localRenderView)
        
        signalingService.delegate = self
        signalingService.connect()
        
        makeOfferButton.addTarget(self, action: #selector(makeOfferAction), for: .touchUpInside)
        hangUpButton.addTarget(self, action: #selector(hangUpAction), for: .touchUpInside)
        sendMessageButton.addTarget(self, action: #selector(sendMessageAction), for: .touchUpInside)
        
        #if !targetEnvironment(simulator)
        videoCapturerService.startCaptureLocalVideo(position: .front, frame: .captureFramePreset960X540) { _ in
            
        }
        #endif
    }
    
    @objc private func makeOfferAction(_ sender: UIButton) {
        if !webRTCService.isConnected {
            connect { [weak self] res in
                if case let .success(sdp) = res {
                    self?.signalingService.sendSDP(sessionDescription: sdp)
                } else {
                    print("makeOffer faild")
                }
            }
        }
    }
    
    @objc private func hangUpAction(_ sender: UIButton) {
        if webRTCService.isConnected {
            webRTCService.disconnect()
        }
    }
    
    @objc private func sendMessageAction(_ sender: UIButton) {
        if let message = inputBox.text {
            webRTCService.sendMessge(message: message)
            inputBox.text = ""
        }
    }
    
    private func connect(_ completionHandler: WebRTCServiceResultHandler?) {
        if signalingService.isConnected == false {
            signalingService.connect()
        }
        
        if !webRTCService.isConnected {
            webRTCService.connect(completionHandler)
        }
    }
    
    private func updateUI() {
        if isConnected {
            stateLabel.text = "Connected"
            stateLabel.textColor = .systemGreen
        } else {
            stateLabel.text = "DisConnected"
            stateLabel.textColor = .systemRed
        }
    }
}

extension ViewController: WebRTCServiceDelegate {
    func didGenerateCandidate(service: WebRTCService, iceCandidate: RTCIceCandidate) {
        signalingService.sendCandidate(iceCandidate: iceCandidate)
    }
    
    func didIceConnectionStateChanged(service: WebRTCService, iceConnectionState: RTCIceConnectionState) {
        
    }
    
    func didOpenDataChannel(service: WebRTCService) {
        
    }
    
    func didReceiveData(service: WebRTCService, data: Data?) {
        
    }
    
    func didReceiveMessage(service: WebRTCService, message: String?) {
        DispatchQueue.main.async {
            self.messageLabel.text = "New Message: \(message ?? "")"
        }
    }
    
    func didConnectWebRTC(service: WebRTCService) {
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    
    func didDisconnectWebRTC(service: WebRTCService) {
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    
    func didAdd(service: WebRTCService, stream: RTCMediaStream) {
        webRTCService.addRemoteRenderer(renderView.remoteRenderView)
    }
}

extension ViewController: SignalingServiceDelegate {
    func websocketDidConnect(service: SignalingService) {
        print("Web socket did connect")
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    
    func websocketDidDisconnect(service: SignalingService, error: Error?) {
        print("Web socket did disconnect")
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    
    func websocketDidReceiveMessage(service: SignalingService, signalingMessage: SignalingMessage?) {
        print("Web socket did receive message: \(String(describing: signalingMessage))")
        
        guard let signalingMessage = signalingMessage else {
            return
        }
         
        switch signalingMessage.type {
        case .offer:
            if let sdp = signalingMessage.sessionDescription?.sdp {
                webRTCService.receiveOffer(offerSDP: RTCSessionDescription(type: .offer, sdp: sdp)) { [weak self] result in
                    if case let .success(answerSDP) = result {
                        self?.signalingService.sendSDP(sessionDescription: answerSDP)
                    }
                }
            }
        case .answer:
            if let sdp = signalingMessage.sessionDescription?.sdp {
                webRTCService.receiveAnswer(answerSDP: RTCSessionDescription(type: .answer, sdp: sdp))
            }
        case .candidate:
            if let candidate = signalingMessage.candidate {
                webRTCService.receiveCandidate(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            }
        case .unKnown:
            print("Web socket did receive message: unKnown")
        }
    }
    
    func websocketDidReceiveData(service: SignalingService, data: Data) {
        print("Web socket did receive data: \(data)")
    }
}

