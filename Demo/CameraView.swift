//
//  CameraView.swift
//  Demo
//
//  Created by Intala Lab on 15.03.2024.
//

import SwiftUI
import AVKit
//Camera
struct CameraView: UIViewRepresentable {
    var frameSize: CGSize
    
    @Binding var session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIViewType(frame: CGRect(origin: .zero, size: frameSize))
        view.backgroundColor = .clear
        
        let cameraLayer = AVCaptureVideoPreviewLayer(layer: session)
        cameraLayer.frame = .init(origin: .zero, size: frameSize)
        cameraLayer.masksToBounds = true
        view.layer.addSublayer(cameraLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}


