//
//  AuthService.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import Foundation
import Combine
import FirebaseAuth

final class AuthService: ObservableObject {
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        registerAuthStateHandler()
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    // MARK: - Auth State
    
    private func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
            self.errorMessage = nil
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
            self.errorMessage = nil
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // MARK: - Validation
    
    static func validateEmail(_ email: String) -> String? {
        guard !email.isEmpty else { return "Email is required" }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else { return "Invalid email format" }
        return nil
    }
    
    static func validatePassword(_ password: String) -> String? {
        guard !password.isEmpty else { return "Password is required" }
        guard password.count >= 6 else { return "Password must be at least 6 characters" }
        return nil
    }
}
