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
        let rawTheme = userDefaults.string(forKey: "vision_board_current_theme")
            ?? userDefaults.string(forKey: "flutter.vision_board_current_theme")
            ?? userDefaults.string(forKey: "widget_theme")
        
        // Normalize theme name to match iOS widget expectations
        guard let theme = rawTheme else { return nil }
        return normalizeThemeName(theme)
    }
    
    // Normalize Flutter theme names to iOS widget format
    private static func normalizeThemeName(_ theme: String) -> String {
        let lowercased = theme.lowercased()
        
        print("🔧 SharedDataModel: Normalizing theme name '\(theme)'")
        
        // Handle various Flutter theme name formats
        if lowercased.contains("premium") {
            print("✅ Normalized to: Premium Vision Board")
            return "Premium Vision Board"
        } else if lowercased.contains("postit") || lowercased.contains("post-it") || lowercased.contains("post it") {
            print("✅ Normalized to: PostIt Vision Board")
            return "PostIt Vision Board"
        } else if lowercased.contains("ruby") && lowercased.contains("red") {
            print("✅ Normalized to: Ruby Reds Vision Board")
            return "Ruby Reds Vision Board"
        } else if lowercased.contains("winter") && lowercased.contains("warmth") {
            print("✅ Normalized to: Winter Warmth Vision Board")
            return "Winter Warmth Vision Board"
        } else if lowercased.contains("coffee") && lowercased.contains("hue") {
            print("✅ Normalized to: Coffee Hues Vision Board")
            return "Coffee Hues Vision Board"
        } else if lowercased.contains("box") || lowercased.contains("boxy") {
            print("✅ Normalized to: Box Vision Board")
            return "Box Vision Board"
        }
        
        // Return original if no match found
        print("⚠️ No normalization match, returning original: \(theme)")
        return theme
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
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("SharedDataModel: App group not available for getCategories")
            return []
        }
        // Try comma-separated string from HomeWidget first (what Flutter saves via HomeWidget)
        if let categoriesString = userDefaults.string(forKey: "selected_life_areas"), !categoriesString.isEmpty {
            let categories = categoriesString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            print("SharedDataModel: Found categories from comma-separated string: \(categories)")
            return categories
        }
        // Try array format (from SharedPreferences)
        if let categoriesArray = userDefaults.array(forKey: "selected_life_areas") as? [String], !categoriesArray.isEmpty {
            print("SharedDataModel: Found categories from array: \(categoriesArray)")
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
        if !categories.isEmpty {
            print("SharedDataModel: Found categories from indexed keys: \(categories)")
        } else {
            print("SharedDataModel: No categories found")
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
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ SharedDataModel: App group '\(appGroupIdentifier)' not available!")
            return []
        }
        
        print("✅ SharedDataModel: App group accessible for reading todos")
        
        // Try multiple key variations
        var jsonString: String? = nil
        let keysToTry = [
            "vision_board_\(category)",
            "flutter.vision_board_\(category)"
        ]
        
        for key in keysToTry {
            if let data = userDefaults.string(forKey: key), !data.isEmpty {
                jsonString = data
                print("✅ SharedDataModel: Found data for '\(category)' using key '\(key)' (\(data.count) chars)")
                break
            }
        }
        
        // If not found, try theme-specific keys (fallback)
        if jsonString == nil || jsonString!.isEmpty {
            print("⚠️ SharedDataModel: Universal key not found, trying theme-specific key")
            jsonString = getTodos(for: category, theme: theme)
            if jsonString != nil && !jsonString!.isEmpty {
                print("✅ SharedDataModel: Found data using theme-specific key")
            }
        }
        
        guard let jsonString = jsonString, !jsonString.isEmpty else {
            print("❌ SharedDataModel: No data found for category '\(category)' (tried all keys)")
            return []
        }
        
        // Check if it's valid JSON array (not empty)
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "[]" || trimmed.isEmpty {
            print("⚠️ SharedDataModel: Empty array for category '\(category)'")
            return []
        }
        
        // Print first 100 chars for debugging
        let preview = String(trimmed.prefix(100))
        print("📝 SharedDataModel: JSON preview for '\(category)': \(preview)...")
        
        if let data = jsonString.data(using: .utf8) {
            // Try standard decode first
            if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
                print("✅ SharedDataModel: Successfully decoded \(decoded.count) todos for '\(category)' using Codable")
                return decoded
            }
            
            // Fallback: handle both "isDone" and "completed" field names, and "id" field
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                print("📋 SharedDataModel: Parsing JSON array with \(jsonArray.count) items")
                let todos = jsonArray.compactMap { dict -> TodoItem? in
                    // Support both "text" field and check for existence
                    guard let text = dict["text"] as? String else {
                        print("⚠️ SharedDataModel: Missing 'text' field in todo item: \(dict)")
                        return nil
                    }
                    // Handle both "isDone" and "completed" field names
                    let isCompleted = (dict["completed"] as? Bool) ?? (dict["isDone"] as? Bool) ?? false
                    return TodoItem(text: text, isCompleted: isCompleted)
                }
                print("✅ SharedDataModel: Parsed \(todos.count) todos from JSON array for '\(category)'")
                return todos
            } else {
                print("❌ SharedDataModel: Failed to parse JSON for category '\(category)'")
                if let error = try? JSONSerialization.jsonObject(with: data) {
                    print("📄 SharedDataModel: Parsed object type: \(type(of: error))")
                }
            }
        } else {
            print("❌ SharedDataModel: Failed to convert string to data for category '\(category)'")
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
