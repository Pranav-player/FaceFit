//
//  CameraViewModel.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import AVFoundation
import UIKit
import Photos
import Combine

@MainActor
final class CameraViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedFilter: FilterOption = .none
    @Published var detectedFaces: [DetectedFace] = []
    @Published var isCameraRunning = false
    @Published var capturedImage: UIImage?
    @Published var showCapturedImage = false
    @Published var showSaveSuccess = false
    @Published var showSaveError = false
    @Published var errorMessage: String?
    @Published var isFrontCamera = true
    
    // MARK: - Services
    
    let cameraService = CameraService()
    let faceDetectionService = FaceDetectionService()
    let filterRenderer = FilterRenderer()
    private let persistenceService = PersistenceService.shared
    
    // MARK: - Properties
    
    private var overlayView: UIView?
    
    // MARK: - Setup
    
    func setupCamera() {
        cameraService.delegate = self
        cameraService.setupSession()
        
        faceDetectionService.onFacesDetected = { [weak self] faces in
            DispatchQueue.main.async {
                self?.detectedFaces = faces
            }
        }
    }
    
    func startCamera() {
        cameraService.startSession()
        isCameraRunning = true
    }
    
    func stopCamera() {
        cameraService.stopSession()
        isCameraRunning = false
    }
    
    func switchCamera() {
        cameraService.switchCamera()
        isFrontCamera.toggle()
    }
    
    func setOverlayView(_ view: UIView) {
        self.overlayView = view
        filterRenderer.setOverlayView(view)
    }
    
    // MARK: - Filter
    
    func selectFilter(_ filter: FilterOption) {
        selectedFilter = filter
        persistenceService.logFilterUsage(filterName: filter.rawValue)
    }
    
    func updateFilterRendering(viewSize: CGSize) {
        filterRenderer.renderFilters(for: detectedFaces, filter: selectedFilter, in: viewSize)
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() {
        // Capture the overlay view along with camera frame
        guard let overlayView = overlayView else { return }
        
        cameraService.capturePhoto { [weak self] image in
            guard let self = self, let cameraImage = image else { return }
            
            DispatchQueue.main.async {
                // Composite the filter overlay onto the captured image
                let composited = self.compositeFilterOnImage(cameraImage, overlayView: overlayView)
                self.capturedImage = composited
                self.showCapturedImage = true
                
                // Log usage
                self.persistenceService.logFilterUsage(
                    filterName: self.selectedFilter.rawValue,
                    photoSaved: false
                )
            }
        }
    }
    
    func savePhotoToLibrary() {
        guard let image = capturedImage else { return }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Photo library access denied"
                    self?.showSaveError = true
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.showSaveSuccess = true
                        self?.persistenceService.logFilterUsage(
                            filterName: self?.selectedFilter.rawValue ?? "unknown",
                            photoSaved: true
                        )
                    } else {
                        self?.errorMessage = error?.localizedDescription ?? "Failed to save photo"
                        self?.showSaveError = true
                    }
                }
            }
        }
    }
    
    func dismissCapturedImage() {
        capturedImage = nil
        showCapturedImage = false
    }
    
    // MARK: - Compositing
    
    private func compositeFilterOnImage(_ image: UIImage, overlayView: UIView) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: overlayView.bounds.size)
        return renderer.image { context in
            // Draw the camera image scaled to fill
            image.draw(in: overlayView.bounds)
            // Draw the overlay layers
            overlayView.layer.render(in: context.cgContext)
        }
    }
}

// MARK: - CameraServiceDelegate

extension CameraViewModel: @preconcurrency CameraServiceDelegate {
    func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
        faceDetectionService.detectFaces(in: sampleBuffer)
    }
}
