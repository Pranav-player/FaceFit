//
//  CameraView.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import SwiftUI
import Combine

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @ObservedObject var authViewModel: AuthViewModel
    @State private var viewSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Full-screen camera preview
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                CameraPreviewView(
                    cameraService: viewModel.cameraService,
                    onOverlayViewReady: { overlayView in
                        viewModel.setOverlayView(overlayView)
                    }
                )
                .ignoresSafeArea()
                .onAppear {
                    viewSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    viewSize = newSize
                }
            }
            .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                // Top bar
                topBar
                
                Spacer()
                
                // Face detection indicator
                if !viewModel.detectedFaces.isEmpty && viewModel.selectedFilter != .none {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Face Detected")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .transition(.opacity)
                }
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Filter selector
                    FilterSelectorView(
                        selectedFilter: $viewModel.selectedFilter,
                        onFilterSelected: { filter in
                            viewModel.selectFilter(filter)
                        }
                    )
                    .padding(.bottom, 4)
                    
                    // Capture button & controls
                    HStack(spacing: 40) {
                        // Switch camera
                        Button(action: { viewModel.switchCamera() }) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        // Capture button
                        Button(action: { viewModel.capturePhoto() }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 76, height: 76)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 64, height: 64)
                            }
                        }
                        
                        // Sign out
                        Button(action: { authViewModel.signOut() }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
        }
        .onAppear {
            viewModel.setupCamera()
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .onChange(of: viewModel.detectedFaces) { _, _ in
            viewModel.updateFilterRendering(viewSize: viewSize)
        }
        .onChange(of: viewModel.selectedFilter) { _, _ in
            viewModel.updateFilterRendering(viewSize: viewSize)
        }
        .sheet(isPresented: $viewModel.showCapturedImage) {
            CapturedImageView(viewModel: viewModel)
        }
        .alert("Saved!", isPresented: $viewModel.showSaveSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Photo saved to your library successfully.")
        }
        .alert("Error", isPresented: $viewModel.showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Failed to save photo.")
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FaceFit AR")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(viewModel.detectedFaces.isEmpty ? "No face detected" : "\(viewModel.detectedFaces.count) face(s)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Front/back camera indicator
            HStack(spacing: 4) {
                Image(systemName: viewModel.isFrontCamera ? "person.fill" : "camera.fill")
                    .font(.caption)
                Text(viewModel.isFrontCamera ? "Front" : "Back")
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Captured Image View

struct CapturedImageView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .ignoresSafeArea()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Discard") {
                        viewModel.dismissCapturedImage()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.savePhotoToLibrary()
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}
