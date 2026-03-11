//
//  FaceLandmarks.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import Foundation
import Vision

struct DetectedFace: Equatable {
    let boundingBox: CGRect
    let landmarks: VNFaceLandmarks2D?
    let roll: CGFloat
    let yaw: CGFloat

    static func == (lhs: DetectedFace, rhs: DetectedFace) -> Bool {
        lhs.boundingBox == rhs.boundingBox &&
        lhs.roll == rhs.roll &&
        lhs.yaw == rhs.yaw
    }
    
    var leftEyeCenter: CGPoint? {
        guard let leftEye = landmarks?.leftEye else { return nil }
        let points = leftEye.normalizedPoints
        guard !points.isEmpty else { return nil }
        let avgX = points.map(\.x).reduce(0, +) / CGFloat(points.count)
        let avgY = points.map(\.y).reduce(0, +) / CGFloat(points.count)
        return CGPoint(x: avgX, y: avgY)
    }
    
    var rightEyeCenter: CGPoint? {
        guard let rightEye = landmarks?.rightEye else { return nil }
        let points = rightEye.normalizedPoints
        guard !points.isEmpty else { return nil }
        let avgX = points.map(\.x).reduce(0, +) / CGFloat(points.count)
        let avgY = points.map(\.y).reduce(0, +) / CGFloat(points.count)
        return CGPoint(x: avgX, y: avgY)
    }
    
    var noseCenter: CGPoint? {
        guard let nose = landmarks?.nose else { return nil }
        let points = nose.normalizedPoints
        guard !points.isEmpty else { return nil }
        let avgX = points.map(\.x).reduce(0, +) / CGFloat(points.count)
        let avgY = points.map(\.y).reduce(0, +) / CGFloat(points.count)
        return CGPoint(x: avgX, y: avgY)
    }
    
    var faceContourPoints: [CGPoint]? {
        return landmarks?.faceContour?.normalizedPoints.map { CGPoint(x: $0.x, y: $0.y) }
    }
    
    /// Convert a normalized landmark point to the view coordinate system
    func convertToViewPoint(_ normalizedPoint: CGPoint, in viewSize: CGSize) -> CGPoint {
        let faceBoundsInView = convertBoundingBox(to: viewSize)
        let x = faceBoundsInView.origin.x + normalizedPoint.x * faceBoundsInView.width
        let y = faceBoundsInView.origin.y + (1 - normalizedPoint.y) * faceBoundsInView.height
        return CGPoint(x: x, y: y)
    }
    
    /// Convert the bounding box from Vision coordinates to view coordinates
    func convertBoundingBox(to viewSize: CGSize) -> CGRect {
        let x = boundingBox.origin.x * viewSize.width
        let y = (1 - boundingBox.origin.y - boundingBox.height) * viewSize.height
        let width = boundingBox.width * viewSize.width
        let height = boundingBox.height * viewSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
