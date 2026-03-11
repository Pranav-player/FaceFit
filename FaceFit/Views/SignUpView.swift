//
//  SignUpView.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import SwiftUI
import Combine

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.05, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 20)
                    
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Join FaceFit AR today")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Sign Up Form
                    VStack(spacing: 18) {
                        // Display Name
                        CustomTextField(
                            icon: "person.fill",
                            placeholder: "Display Name",
                            text: $viewModel.displayName
                        )
                        
                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $viewModel.email
                            )
                            if let error = viewModel.emailError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 8)
                            }
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $viewModel.password,
                                isSecure: true
                            )
                            if let error = viewModel.passwordError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 8)
                            }
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 6) {
                            CustomTextField(
                                icon: "lock.shield.fill",
                                placeholder: "Confirm Password",
                                text: $viewModel.confirmPassword,
                                isSecure: true
                            )
                            if let error = viewModel.confirmPasswordError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 8)
                            }
                        }
                        
                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Sign Up Button
                        Button(action: { viewModel.signUp() }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isSignUpFormValid ? 1.0 : 0.6)
                    }
                    .padding(.horizontal, 28)
                    
                    // Back to login
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(.pink)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
