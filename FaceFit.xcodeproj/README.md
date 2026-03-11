//
//  FaceFitApp.swift
//  FaceFit
//
//  Created by FaceFit Team on 2026-03-11.
//

import SwiftUI
import FirebaseCore

@main
struct FaceFitApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
