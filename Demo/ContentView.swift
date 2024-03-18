//
//  ContentView.swift
//  Demo
//
//  Created by Intala Lab on 15.03.2024.
//

import SwiftUI
import AVKit

struct ContentView: View {
    
    @State private var isScanning: Bool = false
    @State private var session: AVCaptureSession = .init()
    @State private var qrOutput: AVCaptureMetadataOutput = .init()
    @State private var cameraPermission: Permission = .idle
    // error
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @Environment(\.openURL) private var  openURL
    @StateObject private var qrDelegate = QRScannerDelegate()
    @State private var scannedCode: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                
            } label: {
                Image(systemName: "xmark")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("QR Kodu Okutunuz")
                .font(.title)
                .foregroundColor(.black .opacity(0.8))
                .padding(.top, 20)
            
            Text("Tarama otomatik başlayacaktır")
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer()
            
            //Scan
            GeometryReader {
                let size = $0.size
                
                ZStack {
                    CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                        .scaleEffect(0.97)
                    
                    ForEach(0...4, id: \.self) { index in
                        let rotation = Double(index) * 90
                        
                        RoundedRectangle(cornerRadius: 2, style: .circular)
                            .trim(from: 0.60, to: 0.65)
                            .stroke(Color(.blue) ,style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                            .rotationEffect(.init(degrees: rotation))
                    }
                    
                    
                }
                //kare
                .frame(width: size.width, height: size.width)
                //animasyon
                .overlay(alignment: .top, content: {
                    Rectangle()
                        .fill(Color(.blue))
                        .frame(height: 2.5)
                        .shadow(color: .black .opacity(0.8), radius: 8, x: 0, y: isScanning ? 15 :  -15)
                        .offset(y: isScanning ? size.width : 0)
                })
                //ortala
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 45)
            
            Spacer(minLength: 15)
            
            Button {
                if !session.isRunning && cameraPermission == .approved {
                    reactivateCamera()
                    activateScannerAnimation()
                }
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            Spacer(minLength: 45)
        }
        .padding(15)
        .onAppear(perform: checkCameraPermission)
        .alert(errorMessage, isPresented: $showError) {
            if cameraPermission == .denied {
                Button("Ayarlar") {
                    let settingsString = UIApplication.openSettingsURLString
                    if let settingsURL = URL(string: settingsString) {
                        //ayarları açma kısmı
                        openURL(settingsURL)
                    }
                }
                Button("İptal", role: .cancel) {
                    
                }
            }
        }
        //old value bug??? 
        .onChange(of: qrDelegate.scannedCode) { oldValue, newValue in
            if let code = newValue {
                scannedCode = code
                session.stopRunning()
                deActivateScannerAnimation()
                qrDelegate.scannedCode = nil
            }
        }
    }
    func reactivateCamera() {
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    //aktive
    func activateScannerAnimation() {
        withAnimation(.easeInOut(duration: 0.80).delay(0.1).repeatForever(autoreverses: true)) {
            isScanning = true
        }
    }
    //iptal
    func deActivateScannerAnimation() {
        withAnimation(.easeInOut(duration: 0.80)) {
            isScanning = false
        }
    }
    
    func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized:
                cameraPermission = .approved
                if session.inputs.isEmpty {
                    setupCamera()
                } else {
                    session.startRunning()
                }
                
                case .notDetermined:
                if await AVCaptureDevice.requestAccess(for: .video) {
                    cameraPermission = .approved
                    setupCamera()
                } else {
                    cameraPermission = .denied
                presentError("Lütfen uygulamayı kullanmak için kameraya erişim izni verin")
                }
                case .denied, .restricted:
                cameraPermission = .denied
                presentError("Lütfen uygulamayı kullanmak için kameraya erişim izni verin")
                default: break
            }
        }
    }
    func setupCamera() {
        do {
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else {
                presentError("Bilinmeyen Cihaz")
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
                presentError("Bilinmeyen Değer")
                return
            }
            
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutput)
            
            qrOutput.metadataObjectTypes = [.qr]
            
            qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            activateScannerAnimation()
        } catch {
            presentError(error.localizedDescription)
        }
    }
    
    func presentError(_ message: String) {
        errorMessage = message
        showError.toggle()
    }
    
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
