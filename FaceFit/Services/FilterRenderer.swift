//
//  FilterRenderer.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import UIKit
import QuartzCore

/// Renders face filter overlays using CoreAnimation layers on top of the camera preview
final class FilterRenderer {
    
    // MARK: - Properties
    
    private weak var overlayView: UIView?
    private var filterLayers: [CALayer] = []
    
    // MARK: - Setup
    
    func setOverlayView(_ view: UIView) {
        self.overlayView = view
    }
    
    // MARK: - Rendering
    
    func renderFilters(for faces: [DetectedFace], filter: FilterOption, in viewSize: CGSize) {
        clearFilters()
        
        guard filter != .none, let overlayView = overlayView else { return }
        
        for face in faces {
            let faceRect = face.convertBoundingBox(to: viewSize)
            
            switch filter {
            case .none:
                break
            case .glasses:
                renderGlasses(face: face, faceRect: faceRect, viewSize: viewSize, on: overlayView)
            case .crown:
                renderCrown(face: face, faceRect: faceRect, viewSize: viewSize, on: overlayView)
            case .mask:
                renderMask(face: face, faceRect: faceRect, viewSize: viewSize, on: overlayView)
            case .animalEars:
                renderAnimalEars(face: face, faceRect: faceRect, viewSize: viewSize, on: overlayView)
            case .decorative:
                renderDecorative(face: face, faceRect: faceRect, viewSize: viewSize, on: overlayView)
            }
        }
    }
    
    func clearFilters() {
        filterLayers.forEach { $0.removeFromSuperlayer() }
        filterLayers.removeAll()
    }
    
    // MARK: - Filter Drawings
    
    // --- Glasses ---
    private func renderGlasses(face: DetectedFace, faceRect: CGRect, viewSize: CGSize, on view: UIView) {
        guard let leftEye = face.leftEyeCenter, let rightEye = face.rightEyeCenter else { return }
        
        let leftPoint = face.convertToViewPoint(leftEye, in: viewSize)
        let rightPoint = face.convertToViewPoint(rightEye, in: viewSize)
        
        let eyeDistance = hypot(rightPoint.x - leftPoint.x, rightPoint.y - leftPoint.y)
        let lensRadius = eyeDistance * 0.35
        let bridgeY = (leftPoint.y + rightPoint.y) / 2
        let angle = atan2(rightPoint.y - leftPoint.y, rightPoint.x - leftPoint.x)
        
        let glassesLayer = CAShapeLayer()
        let path = UIBezierPath()
        
        // Left lens
        path.addArc(withCenter: leftPoint, radius: lensRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        // Right lens
        path.addArc(withCenter: rightPoint, radius: lensRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        // Bridge
        path.move(to: CGPoint(x: leftPoint.x + lensRadius * 0.8, y: bridgeY))
        path.addLine(to: CGPoint(x: rightPoint.x - lensRadius * 0.8, y: bridgeY))
        // Left arm
        path.move(to: CGPoint(x: leftPoint.x - lensRadius, y: leftPoint.y))
        path.addLine(to: CGPoint(x: leftPoint.x - lensRadius - eyeDistance * 0.4, y: leftPoint.y + lensRadius * 0.3))
        // Right arm
        path.move(to: CGPoint(x: rightPoint.x + lensRadius, y: rightPoint.y))
        path.addLine(to: CGPoint(x: rightPoint.x + lensRadius + eyeDistance * 0.4, y: rightPoint.y + lensRadius * 0.3))
        
        glassesLayer.path = path.cgPath
        glassesLayer.strokeColor = UIColor.systemBlue.cgColor
        glassesLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1).cgColor
        glassesLayer.lineWidth = 3.0
        glassesLayer.lineCap = .round
        
        // Apply rotation for head tilt
        glassesLayer.setAffineTransform(CGAffineTransform(rotationAngle: face.roll))
        
        addLayer(glassesLayer, to: view)
    }
    
    // --- Crown ---
    private func renderCrown(face: DetectedFace, faceRect: CGRect, viewSize: CGSize, on view: UIView) {
        let crownLayer = CAShapeLayer()
        let path = UIBezierPath()
        
        let crownWidth = faceRect.width * 1.1
        let crownHeight = faceRect.height * 0.4
        let crownX = faceRect.midX - crownWidth / 2
        let crownY = faceRect.minY - crownHeight * 0.9
        
        // Base of crown
        path.move(to: CGPoint(x: crownX, y: crownY + crownHeight))
        // Left spike
        path.addLine(to: CGPoint(x: crownX, y: crownY + crownHeight * 0.3))
        path.addLine(to: CGPoint(x: crownX + crownWidth * 0.15, y: crownY + crownHeight * 0.6))
        // Center-left spike
        path.addLine(to: CGPoint(x: crownX + crownWidth * 0.3, y: crownY))
        path.addLine(to: CGPoint(x: crownX + crownWidth * 0.4, y: crownY + crownHeight * 0.5))
        // Center spike (tallest)
        path.addLine(to: CGPoint(x: crownX + crownWidth * 0.5, y: crownY - crownHeight * 0.1))
        path.addLine(to: CGPoint(x: crownX + crownWidth * 0.6, y: crownY + crownHeight * 0.5))
        // Center-right spike
        path.addLine(to: CGPoint(x: crownX + crownWidth * 0.7, y: crownY))
        path.addLine(to: CGPoint(x: crownX + crownWidth * 0.85, y: crownY + crownHeight * 0.6))
        // Right spike
        path.addLine(to: CGPoint(x: crownX + crownWidth, y: crownY + crownHeight * 0.3))
        path.addLine(to: CGPoint(x: crownX + crownWidth, y: crownY + crownHeight))
        path.close()
        
        crownLayer.path = path.cgPath
        crownLayer.fillColor = UIColor.systemYellow.cgColor
        crownLayer.strokeColor = UIColor.orange.cgColor
        crownLayer.lineWidth = 2.0
        crownLayer.shadowColor = UIColor.orange.cgColor
        crownLayer.shadowRadius = 6
        crownLayer.shadowOpacity = 0.6
        crownLayer.shadowOffset = .zero
        
        // Add jewel dots on the crown spikes
        let jewelPositions = [
            CGPoint(x: crownX + crownWidth * 0.3, y: crownY + crownHeight * 0.15),
            CGPoint(x: crownX + crownWidth * 0.5, y: crownY + crownHeight * 0.05),
            CGPoint(x: crownX + crownWidth * 0.7, y: crownY + crownHeight * 0.15)
        ]
        
        for pos in jewelPositions {
            let jewelLayer = CAShapeLayer()
            let jewelPath = UIBezierPath(arcCenter: pos, radius: crownWidth * 0.03, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            jewelLayer.path = jewelPath.cgPath
            jewelLayer.fillColor = UIColor.red.cgColor
            addLayer(jewelLayer, to: view)
        }
        
        addLayer(crownLayer, to: view)
    }
    
    // --- Mask ---
    private func renderMask(face: DetectedFace, faceRect: CGRect, viewSize: CGSize, on view: UIView) {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath()
        
        // Masquerade-style mask covering eyes area
        let maskWidth = faceRect.width * 1.2
        let maskHeight = faceRect.height * 0.35
        let maskX = faceRect.midX - maskWidth / 2
        let maskY = faceRect.minY + faceRect.height * 0.2
        
        // Outer mask shape — elegant pointed ends
        path.move(to: CGPoint(x: maskX, y: maskY + maskHeight * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: maskX + maskWidth * 0.5, y: maskY),
            controlPoint: CGPoint(x: maskX + maskWidth * 0.15, y: maskY - maskHeight * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: maskX + maskWidth, y: maskY + maskHeight * 0.5),
            controlPoint: CGPoint(x: maskX + maskWidth * 0.85, y: maskY - maskHeight * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: maskX + maskWidth * 0.5, y: maskY + maskHeight),
            controlPoint: CGPoint(x: maskX + maskWidth * 0.85, y: maskY + maskHeight * 1.1)
        )
        path.addQuadCurve(
            to: CGPoint(x: maskX, y: maskY + maskHeight * 0.5),
            controlPoint: CGPoint(x: maskX + maskWidth * 0.15, y: maskY + maskHeight * 1.1)
        )
        
        // Eye holes
        let eyeHoleWidth = maskWidth * 0.22
        let eyeHoleHeight = maskHeight * 0.4
        let leftEyeHole = UIBezierPath(ovalIn: CGRect(
            x: maskX + maskWidth * 0.15,
            y: maskY + maskHeight * 0.3,
            width: eyeHoleWidth,
            height: eyeHoleHeight
        ))
        let rightEyeHole = UIBezierPath(ovalIn: CGRect(
            x: maskX + maskWidth * 0.63,
            y: maskY + maskHeight * 0.3,
            width: eyeHoleWidth,
            height: eyeHoleHeight
        ))
        
        path.append(leftEyeHole.reversing())
        path.append(rightEyeHole.reversing())
        
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.systemGreen.withAlphaComponent(0.7).cgColor
        maskLayer.strokeColor = UIColor.systemGreen.cgColor
        maskLayer.lineWidth = 2.0
        maskLayer.shadowColor = UIColor.green.cgColor
        maskLayer.shadowRadius = 8
        maskLayer.shadowOpacity = 0.5
        maskLayer.shadowOffset = .zero
        
        addLayer(maskLayer, to: view)
    }
    
    // --- Animal Ears ---
    private func renderAnimalEars(face: DetectedFace, faceRect: CGRect, viewSize: CGSize, on view: UIView) {
        let earWidth = faceRect.width * 0.3
        let earHeight = faceRect.height * 0.5
        
        // Left ear
        let leftEarLayer = CAShapeLayer()
        let leftPath = UIBezierPath()
        let leftBase = CGPoint(x: faceRect.minX + faceRect.width * 0.15, y: faceRect.minY)
        leftPath.move(to: leftBase)
        leftPath.addQuadCurve(
            to: CGPoint(x: leftBase.x + earWidth, y: leftBase.y),
            controlPoint: CGPoint(x: leftBase.x + earWidth * 0.5, y: leftBase.y - earHeight)
        )
        leftPath.close()
        leftEarLayer.path = leftPath.cgPath
        leftEarLayer.fillColor = UIColor.systemOrange.cgColor
        leftEarLayer.strokeColor = UIColor.brown.cgColor
        leftEarLayer.lineWidth = 2.0
        
        // Left ear inner
        let leftInnerLayer = CAShapeLayer()
        let leftInnerPath = UIBezierPath()
        let leftInnerBase = CGPoint(x: leftBase.x + earWidth * 0.2, y: leftBase.y)
        leftInnerPath.move(to: leftInnerBase)
        leftInnerPath.addQuadCurve(
            to: CGPoint(x: leftInnerBase.x + earWidth * 0.6, y: leftInnerBase.y),
            controlPoint: CGPoint(x: leftInnerBase.x + earWidth * 0.3, y: leftInnerBase.y - earHeight * 0.65)
        )
        leftInnerPath.close()
        leftInnerLayer.path = leftInnerPath.cgPath
        leftInnerLayer.fillColor = UIColor.systemPink.withAlphaComponent(0.6).cgColor
        
        // Right ear
        let rightEarLayer = CAShapeLayer()
        let rightPath = UIBezierPath()
        let rightBase = CGPoint(x: faceRect.maxX - faceRect.width * 0.15 - earWidth, y: faceRect.minY)
        rightPath.move(to: rightBase)
        rightPath.addQuadCurve(
            to: CGPoint(x: rightBase.x + earWidth, y: rightBase.y),
            controlPoint: CGPoint(x: rightBase.x + earWidth * 0.5, y: rightBase.y - earHeight)
        )
        rightPath.close()
        rightEarLayer.path = rightPath.cgPath
        rightEarLayer.fillColor = UIColor.systemOrange.cgColor
        rightEarLayer.strokeColor = UIColor.brown.cgColor
        rightEarLayer.lineWidth = 2.0
        
        // Right ear inner
        let rightInnerLayer = CAShapeLayer()
        let rightInnerPath = UIBezierPath()
        let rightInnerBase = CGPoint(x: rightBase.x + earWidth * 0.2, y: rightBase.y)
        rightInnerPath.move(to: rightInnerBase)
        rightInnerPath.addQuadCurve(
            to: CGPoint(x: rightInnerBase.x + earWidth * 0.6, y: rightInnerBase.y),
            controlPoint: CGPoint(x: rightInnerBase.x + earWidth * 0.3, y: rightInnerBase.y - earHeight * 0.65)
        )
        rightInnerPath.close()
        rightInnerLayer.path = rightInnerPath.cgPath
        rightInnerLayer.fillColor = UIColor.systemPink.withAlphaComponent(0.6).cgColor
        
        // Nose dot (cute animal nose)
        if let noseCenter = face.noseCenter {
            let nosePoint = face.convertToViewPoint(noseCenter, in: viewSize)
            let noseLayer = CAShapeLayer()
            let noseSize = faceRect.width * 0.08
            let nosePath = UIBezierPath(ovalIn: CGRect(
                x: nosePoint.x - noseSize,
                y: nosePoint.y - noseSize * 0.7,
                width: noseSize * 2,
                height: noseSize * 1.4
            ))
            noseLayer.path = nosePath.cgPath
            noseLayer.fillColor = UIColor.black.cgColor
            addLayer(noseLayer, to: view)
            
            // Whiskers
            let whiskerLayer = CAShapeLayer()
            let whiskerPath = UIBezierPath()
            let whiskerLength = faceRect.width * 0.3
            for i in -1...1 {
                guard i != 0 else { continue }
                let yOffset = CGFloat(i) * noseSize * 0.8
                // Left whiskers
                whiskerPath.move(to: CGPoint(x: nosePoint.x - noseSize, y: nosePoint.y + yOffset))
                whiskerPath.addLine(to: CGPoint(x: nosePoint.x - noseSize - whiskerLength, y: nosePoint.y + yOffset * 1.5))
                // Right whiskers
                whiskerPath.move(to: CGPoint(x: nosePoint.x + noseSize, y: nosePoint.y + yOffset))
                whiskerPath.addLine(to: CGPoint(x: nosePoint.x + noseSize + whiskerLength, y: nosePoint.y + yOffset * 1.5))
            }
            // Center whiskers
            whiskerPath.move(to: CGPoint(x: nosePoint.x - noseSize, y: nosePoint.y))
            whiskerPath.addLine(to: CGPoint(x: nosePoint.x - noseSize - whiskerLength, y: nosePoint.y))
            whiskerPath.move(to: CGPoint(x: nosePoint.x + noseSize, y: nosePoint.y))
            whiskerPath.addLine(to: CGPoint(x: nosePoint.x + noseSize + whiskerLength, y: nosePoint.y))
            
            whiskerLayer.path = whiskerPath.cgPath
            whiskerLayer.strokeColor = UIColor.darkGray.cgColor
            whiskerLayer.lineWidth = 1.5
            whiskerLayer.fillColor = UIColor.clear.cgColor
            addLayer(whiskerLayer, to: view)
        }
        
        addLayer(leftEarLayer, to: view)
        addLayer(leftInnerLayer, to: view)
        addLayer(rightEarLayer, to: view)
        addLayer(rightInnerLayer, to: view)
    }
    
    // --- Decorative ---
    private func renderDecorative(face: DetectedFace, faceRect: CGRect, viewSize: CGSize, on view: UIView) {
        // Sparkle/star decorations around the face
        let sparklePositions = [
            CGPoint(x: faceRect.minX - faceRect.width * 0.1, y: faceRect.minY + faceRect.height * 0.2),
            CGPoint(x: faceRect.maxX + faceRect.width * 0.1, y: faceRect.minY + faceRect.height * 0.2),
            CGPoint(x: faceRect.midX, y: faceRect.minY - faceRect.height * 0.15),
            CGPoint(x: faceRect.minX + faceRect.width * 0.2, y: faceRect.minY - faceRect.height * 0.05),
            CGPoint(x: faceRect.maxX - faceRect.width * 0.2, y: faceRect.minY - faceRect.height * 0.05),
            CGPoint(x: faceRect.minX - faceRect.width * 0.05, y: faceRect.midY),
            CGPoint(x: faceRect.maxX + faceRect.width * 0.05, y: faceRect.midY)
        ]
        
        let colors: [UIColor] = [.systemPink, .systemYellow, .systemPurple, .systemCyan, .systemMint, .systemPink, .systemYellow]
        let sizes: [CGFloat] = [12, 10, 14, 8, 9, 11, 10]
        
        for (index, position) in sparklePositions.enumerated() {
            let sparkle = createStarLayer(
                at: position,
                size: sizes[index % sizes.count],
                color: colors[index % colors.count]
            )
            addLayer(sparkle, to: view)
        }
        
        // Heart decorations on cheeks
        if let leftEye = face.leftEyeCenter, let rightEye = face.rightEyeCenter {
            let leftCheek = face.convertToViewPoint(
                CGPoint(x: leftEye.x - 0.05, y: leftEye.y - 0.15),
                in: viewSize
            )
            let rightCheek = face.convertToViewPoint(
                CGPoint(x: rightEye.x + 0.05, y: rightEye.y - 0.15),
                in: viewSize
            )
            
            let heartSize = faceRect.width * 0.08
            addLayer(createHeartLayer(at: leftCheek, size: heartSize, color: .systemPink), to: view)
            addLayer(createHeartLayer(at: rightCheek, size: heartSize, color: .systemPink), to: view)
        }
    }
    
    // MARK: - Shape Helpers
    
    private func createStarLayer(at center: CGPoint, size: CGFloat, color: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        let points = 4
        let innerRadius = size * 0.4
        
        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? size : innerRadius
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.close()
        
        layer.path = path.cgPath
        layer.fillColor = color.cgColor
        layer.shadowColor = color.cgColor
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.8
        layer.shadowOffset = .zero
        return layer
    }
    
    private func createHeartLayer(at center: CGPoint, size: CGFloat, color: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        
        let topY = center.y - size * 0.5
        path.move(to: CGPoint(x: center.x, y: center.y + size * 0.5))
        path.addCurve(
            to: CGPoint(x: center.x - size, y: topY),
            controlPoint1: CGPoint(x: center.x - size * 0.1, y: center.y),
            controlPoint2: CGPoint(x: center.x - size, y: center.y - size * 0.2)
        )
        path.addArc(
            withCenter: CGPoint(x: center.x - size * 0.5, y: topY),
            radius: size * 0.5,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        path.addArc(
            withCenter: CGPoint(x: center.x + size * 0.5, y: topY),
            radius: size * 0.5,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + size * 0.5),
            controlPoint1: CGPoint(x: center.x + size, y: center.y - size * 0.2),
            controlPoint2: CGPoint(x: center.x + size * 0.1, y: center.y)
        )
        
        layer.path = path.cgPath
        layer.fillColor = color.withAlphaComponent(0.8).cgColor
        layer.shadowColor = color.cgColor
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.6
        layer.shadowOffset = .zero
        return layer
    }
    
    // MARK: - Layer Management
    
    private func addLayer(_ layer: CALayer, to view: UIView) {
        // Disable implicit animations for smooth real-time updates
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        view.layer.addSublayer(layer)
        CATransaction.commit()
        filterLayers.append(layer)
    }
}
