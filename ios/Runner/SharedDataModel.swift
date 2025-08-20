import Foundation
import WidgetKit

struct SharedDataModel {
    static let appGroupIdentifier = "group.com.mentalfitness.reconstruct.widgets"
    
    // MARK: - Vision Board
    struct VisionBoardData: Codable {
        let title: String
        let description: String
        let goals: [String]
        let lastUpdated: Date
    }
    
    static func getVisionBoardData() -> VisionBoardData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        if let data = userDefaults.data(forKey: "visionBoardData"),
           let visionBoardData = try? JSONDecoder().decode(VisionBoardData.self, from: data) {
            return visionBoardData
        }
        return VisionBoardData(
            title: "My Vision Board",
            description: "Your goals and dreams",
            goals: ["Goal 1", "Goal 2", "Goal 3"],
            lastUpdated: Date()
        )
    }
    
    static func saveVisionBoardData(_ data: VisionBoardData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: "visionBoardData")
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
        return WidgetConfigData(widgetId: widgetId, theme: "default", widgetType: "visionBoard", lastUpdated: Date())
    }
    
    static func saveWidgetConfiguration(_ config: WidgetConfigData) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let encoded = try? JSONEncoder().encode(config) {
            userDefaults.set(encoded, forKey: "widgetConfig_\(config.widgetId)")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
