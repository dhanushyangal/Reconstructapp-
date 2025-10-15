import Foundation
import WidgetKit

struct SharedDataModel {
    static let appGroupIdentifier = "group.com.mentalfitness.reconstruct.widgets"
    
    // MARK: - Notes Data
    struct NoteData: Codable {
        let id: String
        let title: String
        let content: String
        let imagePath: String?
        let colorValue: Int?
        let checklistItems: [ChecklistItem]
        let isPinned: Bool
        let lastEdited: String
    }
    
    struct ChecklistItem: Codable {
        let text: String
        let isChecked: Bool
    }
    
    // MARK: - Vision Board Data
    struct TodoItem: Codable {
        let text: String
        let isCompleted: Bool
    }
    
    // MARK: - Notes Methods
    static func getNotesData() -> [NoteData] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return [] }
        if let data = userDefaults.data(forKey: "notesData"),
           let notesData = try? JSONDecoder().decode([NoteData].self, from: data) {
            return notesData
        }
        return []
    }
    
    static func saveNotesData(_ notesData: [NoteData]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let encoded = try? JSONEncoder().encode(notesData) {
            userDefaults.set(encoded, forKey: "notesData")
            userDefaults.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    static func getSelectedNoteId() -> String? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        return userDefaults.string(forKey: "selectedNoteId")
    }
    
    static func saveSelectedNoteId(_ noteId: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        userDefaults.set(noteId, forKey: "selectedNoteId")
        userDefaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func getNotesTheme() -> String? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        return userDefaults.string(forKey: "notesTheme")
    }
    
    static func saveNotesTheme(_ theme: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        userDefaults.set(theme, forKey: "notesTheme")
        userDefaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Vision Board Methods
    static func saveTheme(_ theme: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        userDefaults.set(theme, forKey: "widget_theme")
        userDefaults.synchronize()
        print("Vision Board theme saved: \(theme)")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func getTheme() -> String? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        return userDefaults.string(forKey: "widget_theme")
    }
    
    static func saveCategories(_ categories: [String]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        for (index, category) in categories.enumerated() {
            userDefaults.set(category, forKey: "category_\(index)")
        }
        for i in categories.count..<5 { // Clear any old categories beyond the new count
            userDefaults.removeObject(forKey: "category_\(i)")
        }
        userDefaults.synchronize()
        print("Vision Board categories saved: \(categories.count)")
    }
    
    static func getCategories() -> [String] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return [] }
        var categories: [String] = []
        for i in 0..<5 { // Max 5 categories
            if let category = userDefaults.string(forKey: "category_\(i)") {
                categories.append(category)
            } else {
                break
            }
        }
        return categories
    }
    
    static func saveTodos(_ todosJson: String, for category: String, theme: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        let key: String
        switch theme {
        case "Premium Vision Board": key = "premium_todos_\(category)"
        case "PostIt Vision Board": key = "postit_todos_\(category)"
        case "Ruby Reds Vision Board": key = "rubyreds_todos_\(category)"
        case "Winter Warmth Vision Board": key = "winterwarmth_todos_\(category)"
        case "Coffee Hues Vision Board": key = "coffeehues_todos_\(category)"
        case "Box Vision Board": key = "BoxThem_todos_\(category)"
        default: key = "todos_\(category)"
        }
        userDefaults.set(todosJson, forKey: key)
        userDefaults.synchronize()
        print("Todos for \(category) in theme \(theme) saved.")
    }
    
    static func getTodos(for category: String, theme: String) -> String? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        let key: String
        switch theme {
        case "Premium Vision Board": key = "premium_todos_\(category)"
        case "PostIt Vision Board": key = "postit_todos_\(category)"
        case "Ruby Reds Vision Board": key = "rubyreds_todos_\(category)"
        case "Winter Warmth Vision Board": key = "winterwarmth_todos_\(category)"
        case "Coffee Hues Vision Board": key = "coffeehues_todos_\(category)"
        case "Box Vision Board": key = "BoxThem_todos_\(category)"
        default: key = "todos_\(category)"
        }
        return userDefaults.string(forKey: key)
    }
    
    // MARK: - Calendar Data Methods
    static func saveCalendarData(_ data: [String: String]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "summer.calendar_theme_2025")
            userDefaults.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    static func getCalendarData() -> [String: String] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return [:] }
        
        // Try the summer calendar data key first
        if let data = userDefaults.data(forKey: "summer.calendar_theme_2025"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            return decoded
        }
        
        // Fallback to string format (legacy)
        if let dataString = userDefaults.string(forKey: "summer.calendar_theme_2025"),
           let data = dataString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            return decoded
        }
        
        return [:]
    }
}
