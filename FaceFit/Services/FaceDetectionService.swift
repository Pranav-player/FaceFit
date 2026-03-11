//
//  FaceDetectionService.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import Vision
import AVFoundation
import CoreImage

final class FaceDetectionService {
    
    // MARK: - Properties
    
    private var sequenceRequestHandler = VNSequenceRequestHandler()
    private var faceDetectionRequest: VNDetectFaceLandmarksRequest?
    
    var onFacesDetected: (([DetectedFace]) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        setupRequest()
    }
    
    private func setupRequest() {
        faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard error == nil else { return }
            self?.handleDetectionResults(request.results)
        }
        faceDetectionRequest?.revision = VNDetectFaceLandmarksRequestRevision3
    }
    
    // MARK: - Detection
    
    func detectFaces(in sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = faceDetectionRequest else { return }
        
        do {
            try sequenceRequestHandler.perform([request], on: pixelBuffer, orientation: .leftMirrored)
        } catch {
            // Reset handler if sequence tracking fails
            sequenceRequestHandler = VNSequenceRequestHandler()
        }
    }
    
    func detectFaces(in pixelBuffer: CVPixelBuffer) {
        guard let request = faceDetectionRequest else { return }
        
        do {
            try sequenceRequestHandler.perform([request], on: pixelBuffer, orientation: .leftMirrored)
        } catch {
            sequenceRequestHandler = VNSequenceRequestHandler()
        }
    }
    
    // MARK: - Results Handling
    
    private func handleDetectionResults(_ results: [Any]?) {
        guard let faceObservations = results as? [VNFaceObservation] else {
            onFacesDetected?([])
            return
        }
        
        let detectedFaces = faceObservations.compactMap { observation -> DetectedFace? in
            let roll = CGFloat(truncating: observation.roll ?? 0)
            let yaw = CGFloat(truncating: observation.yaw ?? 0)
            
            return DetectedFace(
                boundingBox: observation.boundingBox,
                landmarks: observation.landmarks,
                roll: roll,
                yaw: yaw
            )
        }
        
        onFacesDetected?(detectedFaces)
    }
}
