//
//  PersistenceService.swift
//  FaceFit
//
//  Created by Pranav Bhatia on 11/03/26.
//

import Foundation

/// Lightweight persistence using UserDefaults & JSON encoding for user data and filter usage metadata.
/// Can be swapped with Firebase Firestore for cloud sync.
final class PersistenceService {
    
    static let shared = PersistenceService()
    
    private let userDefaultsKey = "com.facefit.currentUser"
    private let filterUsageKey = "com.facefit.filterUsage"
    
    private init() {}
    
    // MARK: - User Data
    
    func saveUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func loadUser() -> AppUser? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(AppUser.self, from: data)
    }
    
    func deleteUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Filter Usage Metadata
    
    func logFilterUsage(filterName: String, photoSaved: Bool = false) {
        var records = loadFilterUsageRecords()
        let record = FilterUsageRecord(filterName: filterName, photoSaved: photoSaved)
        records.append(record)
        
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: filterUsageKey)
        }
        
        // Also update the current user's history
        if var user = loadUser() {
            user.filterUsageHistory.append(record)
            saveUser(user)
        }
    }
    
    func loadFilterUsageRecords() -> [FilterUsageRecord] {
        guard let data = UserDefaults.standard.data(forKey: filterUsageKey) else { return [] }
        return (try? JSONDecoder().decode([FilterUsageRecord].self, from: data)) ?? []
    }
    
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: filterUsageKey)
    }
}
