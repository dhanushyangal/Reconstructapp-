import Foundation
import WidgetKit

struct SharedDataModel {
    static let appGroupIdentifier = "group.com.reconstrect.visionboard.widgets"
    
    // MARK: - Daily Notes
    struct DailyNotesData: Codable {
        let noteText: String
        let noteCount: Int
        let lastUpdated: Date
    }
    
    static func getDailyNotesData() -> DailyNotesData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        
        if let data = userDefaults.data(forKey: "dailyNotesData"),
           let dailyNotes = try? JSONDecoder().decode(DailyNotesData.self, from: data) {
            return dailyNotes
        }
        
        return DailyNotesData(noteText: "No notes yet", noteCount: 0, lastUpdated: Date())
    }
    
    static func saveDailyNotesData(_ data: DailyNotesData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "dailyNotesData")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Weekly Planner
    struct WeeklyPlannerData: Codable {
        let weekGoals: [String]
        let completedTasks: Int
        let totalTasks: Int
        let lastUpdated: Date
    }
    
    static func getWeeklyPlannerData() -> WeeklyPlannerData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        
        if let data = userDefaults.data(forKey: "weeklyPlannerData"),
           let weeklyPlanner = try? JSONDecoder().decode(WeeklyPlannerData.self, from: data) {
            return weeklyPlanner
        }
        
        return WeeklyPlannerData(weekGoals: ["Set your weekly goals"], completedTasks: 0, totalTasks: 0, lastUpdated: Date())
    }
    
    static func saveWeeklyPlannerData(_ data: WeeklyPlannerData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "weeklyPlannerData")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Vision Board
    struct VisionBoardData: Codable {
        let goals: [String]
        let motivation: String
        let lastUpdated: Date
    }
    
    static func getVisionBoardData() -> VisionBoardData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        
        if let data = userDefaults.data(forKey: "visionBoardData"),
           let visionBoard = try? JSONDecoder().decode(VisionBoardData.self, from: data) {
            return visionBoard
        }
        
        return VisionBoardData(goals: ["Define your dreams"], motivation: "Keep dreaming big", lastUpdated: Date())
    }
    
    static func saveVisionBoardData(_ data: VisionBoardData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "visionBoardData")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Calendar
    struct CalendarData: Codable {
        let events: [String]
        let currentMonth: String
        let daysInMonth: Int
        let lastUpdated: Date
    }
    
    static func getCalendarData() -> CalendarData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        
        if let data = userDefaults.data(forKey: "calendarData"),
           let calendar = try? JSONDecoder().decode(CalendarData.self, from: data) {
            return calendar
        }
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let currentMonth = monthFormatter.string(from: Date())
        
        return CalendarData(events: ["No events"], currentMonth: currentMonth, daysInMonth: 30, lastUpdated: Date())
    }
    
    static func saveCalendarData(_ data: CalendarData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "calendarData")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Annual Planner
    struct AnnualPlannerData: Codable {
        let yearGoals: [String]
        let completedMilestones: Int
        let totalMilestones: Int
        let lastUpdated: Date
    }
    
    static func getAnnualPlannerData() -> AnnualPlannerData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        
        if let data = userDefaults.data(forKey: "annualPlannerData"),
           let annualPlanner = try? JSONDecoder().decode(AnnualPlannerData.self, from: data) {
            return annualPlanner
        }
        
        return AnnualPlannerData(yearGoals: ["Set your year goals"], completedMilestones: 0, totalMilestones: 0, lastUpdated: Date())
    }
    
    static func saveAnnualPlannerData(_ data: AnnualPlannerData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "annualPlannerData")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Widget Configuration
    struct WidgetConfigData: Codable {
        let widgetId: String
        let theme: String
        let widgetType: String
        let lastUpdated: Date
    }
    
    static func getWidgetConfiguration(widgetId: String) -> WidgetConfigData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        
        if let data = userDefaults.data(forKey: "widgetConfig_\(widgetId)"),
           let config = try? JSONDecoder().decode(WidgetConfigData.self, from: data) {
            return config
        }
        
        return WidgetConfigData(widgetId: widgetId, theme: "default", widgetType: "dailyNotes", lastUpdated: Date())
    }
    
    static func saveWidgetConfiguration(_ config: WidgetConfigData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        if let encoded = try? JSONEncoder().encode(config) {
            userDefaults.set(encoded, forKey: "widgetConfig_\(config.widgetId)")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
