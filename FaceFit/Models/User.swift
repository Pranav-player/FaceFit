//
//  User.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import Foundation

struct AppUser: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String
    let createdAt: Date
    var lastLoginAt: Date
    var filterUsageHistory: [FilterUsageRecord]
    
    init(id: String, email: String, displayName: String = "") {
        self.id = id
        self.email = email
        self.displayName = displayName.isEmpty ? email.components(separatedBy: "@").first ?? "User" : displayName
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.filterUsageHistory = []
    }
}

struct FilterUsageRecord: Identifiable, Codable {
    let id: String
    let filterName: String
    let usedAt: Date
    let photoSaved: Bool
    
    init(filterName: String, photoSaved: Bool = false) {
        self.id = UUID().uuidString
        self.filterName = filterName
        self.usedAt = Date()
        self.photoSaved = photoSaved
    }
}
