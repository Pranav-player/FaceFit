//
//  AuthViewModel.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var showSignUp = false
    
    // MARK: - Services
    
    private let authService = AuthService()
    private let persistenceService = PersistenceService.shared
    
    // MARK: - Validation
    
    var emailError: String? {
        guard !email.isEmpty else { return nil }
        return AuthService.validateEmail(email)
    }
    
    var passwordError: String? {
        guard !password.isEmpty else { return nil }
        return AuthService.validatePassword(password)
    }
    
    var confirmPasswordError: String? {
        guard !confirmPassword.isEmpty else { return nil }
        guard confirmPassword == password else { return "Passwords do not match" }
        return nil
    }
    
    var isLoginFormValid: Bool {
        AuthService.validateEmail(email) == nil &&
        AuthService.validatePassword(password) == nil
    }
    
    var isSignUpFormValid: Bool {
        isLoginFormValid && confirmPassword == password
    }
    
    // MARK: - Init
    
    init() {
        // Check if user session exists
        if authService.currentUser != nil {
            isAuthenticated = true
        }
    }
    
    // MARK: - Actions
    
    func signIn() {
        guard isLoginFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                
                // Save/update user locally
                if let firebaseUser = authService.currentUser {
                    var appUser = persistenceService.loadUser() ?? AppUser(id: firebaseUser.uid, email: email)
                    appUser.lastLoginAt = Date()
                    persistenceService.saveUser(appUser)
                }
                
                isAuthenticated = true
                isLoading = false
                clearForm()
            } catch {
                let nsError = error as NSError
                print("🔴 Sign In Error: \(error)")
                print("🔴 Error Domain: \(nsError.domain)")
                print("🔴 Error Code: \(nsError.code)")
                print("🔴 Error UserInfo: \(nsError.userInfo)")
                
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("🔴 Underlying Error: \(underlyingError)")
                    print("🔴 Underlying UserInfo: \(underlyingError.userInfo)")
                }
                
                errorMessage = mapFirebaseError(nsError)
                isLoading = false
            }
        }
    }
    
    func signUp() {
        guard isSignUpFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signUp(email: email, password: password)
                
                // Create and save user locally
                if let firebaseUser = authService.currentUser {
                    let appUser = AppUser(id: firebaseUser.uid, email: email, displayName: displayName)
                    persistenceService.saveUser(appUser)
                }
                
                isAuthenticated = true
                isLoading = false
                clearForm()
            } catch {
                let nsError = error as NSError
                print("🔴 Sign Up Error: \(error)")
                print("🔴 Error Domain: \(nsError.domain)")
                print("🔴 Error Code: \(nsError.code)")
                print("🔴 Error UserInfo: \(nsError.userInfo)")
                
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("🔴 Underlying Error: \(underlyingError)")
                    print("🔴 Underlying UserInfo: \(underlyingError.userInfo)")
                }
                
                errorMessage = mapFirebaseError(nsError)
                isLoading = false
            }
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            isAuthenticated = false
            clearForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func mapFirebaseError(_ error: NSError) -> String {
        // Firebase Auth error codes
        guard error.domain == "FIRAuthErrorDomain" || error.domain == AuthErrorDomain else {
            return error.localizedDescription
        }
        
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "The email address is invalid."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account with this email already exists."
        case AuthErrorCode.weakPassword.rawValue:
            return "The password is too weak. Use at least 6 characters."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later."
        case AuthErrorCode.internalError.rawValue:
            // Check for underlying details
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("🔴 Firebase internal error details: \(underlyingError.userInfo)")
            }
            return "Firebase configuration error. Please verify GoogleService-Info.plist has valid credentials (not placeholder values)."
        default:
            return error.localizedDescription
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        errorMessage = nil
    }
}
