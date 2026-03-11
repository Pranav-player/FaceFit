//
//  FilterOption.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import Foundation
import SwiftUI

enum FilterOption: String, CaseIterable, Identifiable {
    case none
    case glasses
    case crown
    case mask
    case animalEars
    case decorative

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .glasses: return "Glasses"
        case .crown: return "Crown"
        case .mask: return "Mask"
        case .animalEars: return "Ears"
        case .decorative: return "Decor"
        }
    }

    var iconName: String {
        switch self {
        case .none: return "xmark.circle"
        case .glasses: return "eyeglasses"
        case .crown: return "crown.fill"
        case .mask: return "theatermask.and.paintbrush"
        case .animalEars: return "hare.fill"
        case .decorative: return "sparkles"
        }
    }

    var filterColor: Color {
        switch self {
        case .none: return .gray
        case .glasses: return .blue
        case .crown: return .yellow
        case .mask: return .green
        case .animalEars: return .orange
        case .decorative: return .pink
        }
    }
}
