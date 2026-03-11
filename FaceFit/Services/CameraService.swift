//
//  CameraService.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import AVFoundation
import UIKit

protocol CameraServiceDelegate: AnyObject {
    @MainActor func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer)
}

final class CameraService: NSObject {
    
    // MARK: - Properties
    
    private let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.facefit.camera.session", qos: .userInteractive)
    private let videoOutputQueue = DispatchQueue(label: "com.facefit.camera.videoOutput", qos: .userInteractive)
    
    private var currentCameraPosition: AVCaptureDevice.Position = .front
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    
    weak var delegate: CameraServiceDelegate?
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        if let connection = layer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        return layer
    }
    
    var isRunning: Bool {
        captureSession.isRunning
    }
    
    // MARK: - Setup
    
    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.configureSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.sessionQueue.async { [weak self] in
                            self?.configureSession()
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        for input in captureSession.inputs { captureSession.removeInput(input) }
        for output in captureSession.outputs { captureSession.removeOutput(output) }
        
        // Add video input (current camera)
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            captureSession.commitConfiguration()
            return
        }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: camera)
        } catch {
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        do {
            try camera.lockForConfiguration()
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            camera.unlockForConfiguration()
        } catch {
            // Could not lock for configuration; continue without custom settings
        }
        
        // Add video output
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = (currentCameraPosition == .front)
            }
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    // MARK: - Controls
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    func switchCamera() {
        currentCameraPosition = (currentCameraPosition == .front) ? .back : .front
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let wasRunning = self.captureSession.isRunning
            self.configureSession()
            if wasRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCaptureCompletion = { image in DispatchQueue.main.async { completion(image) } }
        
        guard photoOutput.isLivePhotoCaptureSupported || !photoOutput.availablePhotoCodecTypes.isEmpty else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    @MainActor func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let delegate = delegate {
            delegate.cameraService(self, didOutput: sampleBuffer)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    @MainActor func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            photoCaptureCompletion?(nil)
            return
        }
        photoCaptureCompletion?(image)
    }
}
