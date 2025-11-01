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
        
        // Manual initializer
        init(text: String, isCompleted: Bool) {
            self.text = text
            self.isCompleted = isCompleted
        }
        
        // Flutter format uses "isDone" instead of "isCompleted"
        enum CodingKeys: String, CodingKey {
            case text
            case isCompleted
            case isDone
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            text = try container.decode(String.self, forKey: .text)
            // Support both "isCompleted" and "isDone" for compatibility
            if let completed = try? container.decode(Bool.self, forKey: .isCompleted) {
                isCompleted = completed
            } else if let done = try? container.decode(Bool.self, forKey: .isDone) {
                isCompleted = done
            } else {
                isCompleted = false
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(text, forKey: .text)
            try container.encode(isCompleted, forKey: .isCompleted)
        }
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
        // Flutter saves theme with these keys
        return userDefaults.string(forKey: "flutter.vision_board_current_theme")
            ?? userDefaults.string(forKey: "vision_board_current_theme")
            ?? userDefaults.string(forKey: "widget_theme") // Fallback for old format
    }
    
    static func saveCategories(_ categories: [String]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        // Save categories (max 5)
        let maxCategories = min(categories.count, 5)
        for index in 0..<maxCategories {
            userDefaults.set(categories[index], forKey: "category_\(index)")
        }
        
        // Clear any old categories beyond the new count (only if we have fewer than 5)
        if maxCategories < 5 {
            for i in maxCategories..<5 {
                userDefaults.removeObject(forKey: "category_\(i)")
            }
        }
        
        userDefaults.synchronize()
        print("Vision Board categories saved: \(maxCategories)")
    }
    
    static func getCategories() -> [String] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Vision Board Widget: Failed to access UserDefaults for categories")
            return []
        }
        
        var categories: [String] = []
        for i in 0..<5 { // Max 5 categories
            if let category = userDefaults.string(forKey: "category_\(i)") {
                categories.append(category)
            } else {
                break
            }
        }
        
        print("Vision Board Widget: Loaded \(categories.count) saved categories: \(categories)")
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
        // Flutter uses universal key: vision_board_$category (same across all themes)
        return userDefaults.string(forKey: "vision_board_\(category)")
    }
    
    // Get Vision Board todos as TodoItem array (handles Flutter format)
    static func getVisionBoardTodos(for category: String) -> [TodoItem] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Vision Board Widget: Failed to access UserDefaults for category: \(category)")
            return []
        }
        
        // Try universal key first (Flutter's format)
        var jsonString = userDefaults.string(forKey: "vision_board_\(category)")
        
        // Fallback to flutter. prefix
        if jsonString == nil {
            jsonString = userDefaults.string(forKey: "flutter.vision_board_\(category)")
        }
        
        guard let json = jsonString, !json.isEmpty else {
            print("Vision Board Widget: No data found for category: \(category)")
            return []
        }
        
        print("Vision Board Widget: Found data for \(category): \(json.count) chars")
        
        if let data = json.data(using: .utf8) {
            // Try direct decode first
            if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
                print("Vision Board Widget: Successfully decoded \(decoded.count) todos for \(category)")
                return decoded
            }
            
            // Fallback: handle Flutter's format with "id", "text", "isDone"
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let todos = jsonArray.compactMap { dict -> TodoItem? in
                    guard let text = dict["text"] as? String else { return nil }
                    let isCompleted = (dict["isDone"] as? Bool) ?? (dict["isCompleted"] as? Bool) ?? false
                    return TodoItem(text: text, isCompleted: isCompleted)
                }
                print("Vision Board Widget: Decoded \(todos.count) todos from Flutter format for \(category)")
                return todos
            }
            
            print("Vision Board Widget: Failed to parse JSON for \(category)")
        }
        
        return []
    }
    
    // Get all categories that have todos (prioritize saved categories first)
    static func getCategoriesWithTodos() -> [String] {
        var categoriesWithData: [String] = []
        
        // First, check saved categories (these are the ones user actually selected)
        let savedCategories = getCategories()
        for category in savedCategories {
            let todos = getVisionBoardTodos(for: category)
            if !todos.isEmpty {
                categoriesWithData.append(category)
            }
        }
        
        // If we have saved categories with data, use those
        if !categoriesWithData.isEmpty {
            return categoriesWithData
        }
        
        // Otherwise, scan all possible categories (fallback)
        let allPossibleCategories = [
            "Travel", "Self Care", "Forgive", "Love", "Family", "Career",
            "Health", "Hobbies", "Knowledge", "Social", "Reading", "Food",
            "Music", "Tech", "DIY", "Luxury", "Income", "BMI", "Invest",
            "Inspiration", "Help", "Fitness", "Skill", "Education",
            "Relationships", "Spirituality", "Personal Growth",
            "Financial Planning", "Home & Living", "Technology",
            "Environment", "Community", "Creativity", "Adventure", "Wellness"
        ]
        
        for category in allPossibleCategories {
            if !categoriesWithData.contains(category) {
                let todos = getVisionBoardTodos(for: category)
                if !todos.isEmpty {
                    categoriesWithData.append(category)
                }
            }
        }
        
        return categoriesWithData
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
