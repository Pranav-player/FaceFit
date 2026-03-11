//
//  CameraPreviewView.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import SwiftUI
import AVFoundation

/// UIViewRepresentable that wraps AVCaptureVideoPreviewLayer and an overlay view for filter rendering
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService
    let onOverlayViewReady: (UIView) -> Void
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        
        // Setup preview layer
        let previewLayer = cameraService.previewLayer
        view.previewLayer = previewLayer
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // Setup overlay view for filter layers
        let overlayView = UIView()
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
        view.filterOverlayView = overlayView
        
        // Notify the view model about the overlay view
        DispatchQueue.main.async {
            onOverlayViewReady(overlayView)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Layout is handled in CameraPreviewUIView.layoutSubviews
    }
}

/// Custom UIView that manages preview layer and overlay sizing
final class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var filterOverlayView: UIView?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        filterOverlayView?.frame = bounds
    }
}
