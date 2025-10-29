import Foundation
import WidgetKit

struct SharedDataModel {
    static let appGroupIdentifier = "group.com.reconstrect.visionboard"
    
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
        userDefaults.set(theme, forKey: "vision_board_current_theme") // Also save with Flutter key
        userDefaults.set(theme, forKey: "flutter.vision_board_current_theme") // Also save with Flutter key
        userDefaults.synchronize()
        print("Vision Board theme saved: \(theme)")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func getTheme() -> String? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        // Try Flutter keys first (as that's what Flutter saves), then fallback to widget_theme
        return userDefaults.string(forKey: "vision_board_current_theme")
            ?? userDefaults.string(forKey: "flutter.vision_board_current_theme")
            ?? userDefaults.string(forKey: "widget_theme")
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
        // Try comma-separated string from HomeWidget first (what Flutter saves via HomeWidget)
        if let categoriesString = userDefaults.string(forKey: "selected_life_areas"), !categoriesString.isEmpty {
            return categoriesString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        }
        // Try array format (from SharedPreferences)
        if let categoriesArray = userDefaults.array(forKey: "selected_life_areas") as? [String], !categoriesArray.isEmpty {
            return categoriesArray
        }
        // Fallback to indexed category keys (for compatibility)
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
        // Flutter saves with universal key: "vision_board_\(category)"
        // Try universal key first (as that's what Flutter uses), then theme-specific keys
        if let universalData = userDefaults.string(forKey: "vision_board_\(category)"), !universalData.isEmpty {
            return universalData
        }
        
        // Fallback to theme-specific keys (for backwards compatibility)
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

    // MARK: - Vision Board Todo Methods (with isDone support)
    static func getVisionBoardTodos(for category: String, theme: String) -> [TodoItem] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return [] }
        // Try universal key first (what Flutter uses)
        var jsonString: String? = userDefaults.string(forKey: "vision_board_\(category)")
        
        // If not found, try theme-specific keys
        if jsonString == nil || jsonString!.isEmpty {
            jsonString = getTodos(for: category, theme: theme)
        }
        
        guard let jsonString = jsonString, !jsonString.isEmpty else { return [] }
        
        if let data = jsonString.data(using: .utf8) {
            // Try standard decode first
            if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
                return decoded
            }
            // Fallback: handle both "isDone" and "completed" field names
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.compactMap { dict in
                    guard let text = dict["text"] as? String else { return nil }
                    let isCompleted = (dict["completed"] as? Bool) ?? (dict["isDone"] as? Bool) ?? false
                    return TodoItem(text: text, isCompleted: isCompleted)
                }
            }
        }
        return []
    }
    
    // MARK: - Weekly Planner Methods
    static func getWeeklyTheme() -> String {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return "Floral Weekly Planner" }
        return userDefaults.string(forKey: "flutter.weekly_planner_current_theme")
            ?? userDefaults.string(forKey: "weekly_planner_current_theme")
            ?? "Floral Weekly Planner"
    }

    static func getWeeklyTodos(for day: String) -> [TodoItem] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return [] }
        let jsonString = userDefaults.string(forKey: "flutter.weekly_planner_\(day)")
            ?? userDefaults.string(forKey: "weekly_planner_\(day)")
            ?? "[]"

        if let data = jsonString.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
                return decoded
            }
            // Fallback: tolerate alternate key name "isDone"
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.compactMap { dict in
                    guard let text = dict["text"] as? String else { return nil }
                    let isCompleted = (dict["completed"] as? Bool) ?? (dict["isDone"] as? Bool) ?? false
                    return TodoItem(text: text, isCompleted: isCompleted)
                }
            }
        }
        return []
    }

    // MARK: - Annual Planner Methods
    static func getAnnualTheme() -> String {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return "Floral Monthly Planner" }
        return userDefaults.string(forKey: "flutter.annual_planner_current_theme")
            ?? userDefaults.string(forKey: "annual_planner_current_theme")
            ?? "Floral Monthly Planner"
    }

    static func getAnnualTodos(for month: String) -> [TodoItem] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return [] }
        let jsonString = userDefaults.string(forKey: "flutter.annual_planner_\(month)")
            ?? userDefaults.string(forKey: "annual_planner_\(month)")
            ?? "[]"

        if let data = jsonString.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
                return decoded
            }
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.compactMap { dict in
                    guard let text = dict["text"] as? String else { return nil }
                    let isCompleted = (dict["completed"] as? Bool) ?? (dict["isDone"] as? Bool) ?? false
                    return TodoItem(text: text, isCompleted: isCompleted)
                }
            }
        }
        return []
    }
}
