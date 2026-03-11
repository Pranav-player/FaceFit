//
//  LoginView.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import SwiftUI
import Combine

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
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
                    VStack(spacing: 32) {
                        Spacer().frame(height: 40)
                        
                        // App Logo & Title
                        VStack(spacing: 12) {
                            Image(systemName: "face.smiling.inverse")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .purple.opacity(0.5), radius: 10)
                            
                            Text("FaceFit AR")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Real-Time Face Filters")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                CustomTextField(
                                    icon: "envelope.fill",
                                    placeholder: "Email",
                                    text: $viewModel.email,
                                    isSecure: false
                                )
                                
                                if let error = viewModel.emailError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 8)
                                }
                            }
                            
                            // Password Field
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
                            
                            // Error message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Sign In Button
                            Button(action: { viewModel.signIn() }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Sign In")
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
                            .opacity(viewModel.isLoginFormValid ? 1.0 : 0.6)
                        }
                        .padding(.horizontal, 28)
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            Button("Sign Up") {
                                viewModel.showSignUp = true
                            }
                            .foregroundColor(.pink)
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        
                        Spacer()
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.showSignUp) {
                SignUpView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Custom Text Field

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textContentType(.oneTimeCode)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
