import SwiftUI

enum WidgetTheme: String, CaseIterable, Codable {
    case `default` = "default"
    case postit = "postit"
    case premium = "premium"
    case watercolor = "watercolor"
    case floral = "floral"
    case japanese = "japanese"
    case box = "box"
    case animal = "animal"
    case sport = "sport"
    case coffee = "coffee"
    
    var displayName: String {
        switch self {
        case .default: return "Default Theme"
        case .postit: return "Post-it Theme"
        case .premium: return "Premium Theme"
        case .watercolor: return "Watercolor Theme"
        case .floral: return "Floral Theme"
        case .japanese: return "Japanese Theme"
        case .box: return "Box Vision Board"
        case .animal: return "Ruby Reds Vision Board"
        case .sport: return "Winter Warmth Vision Board"
        case .coffee: return "Coffee Hues Vision Board"
        }
    }
    
    var description: String {
        switch self {
        case .default: return "Clean and simple design"
        case .postit: return "Colorful sticky note style"
        case .premium: return "Elegant and sophisticated"
        case .watercolor: return "Soft, artistic watercolor"
        case .floral: return "Beautiful floral patterns"
        case .japanese: return "Minimalist Japanese design"
        case .box: return "Organized box layout"
        case .animal: return "Warm ruby red tones"
        case .sport: return "Cozy winter colors"
        case .coffee: return "Rich coffee-inspired hues"
        }
    }
    
    var color: Color {
        switch self {
        case .default: return .blue
        case .postit: return .yellow
        case .premium: return .purple
        case .watercolor: return .pink
        case .floral: return .green
        case .japanese: return .gray
        case .box: return .orange
        case .animal: return .red
        case .sport: return .blue
        case .coffee: return .brown
        }
    }
    
    var icon: String {
        switch self {
        case .default: return "circle"
        case .postit: return "note.text"
        case .premium: return "star.fill"
        case .watercolor: return "paintbrush"
        case .floral: return "leaf.fill"
        case .japanese: return "mountain.2.fill"
        case .box: return "square.grid.2x2"
        case .animal: return "heart.fill"
        case .sport: return "snowflake"
        case .coffee: return "cup.and.saucer.fill"
        }
    }
}

enum WidgetType: String, CaseIterable, Codable {
    case dailyNotes = "dailyNotes"
    case weeklyPlanner = "weeklyPlanner"
    case visionBoard = "visionBoard"
    case calendar = "calendar"
    case annualPlanner = "annualPlanner"
    
    var displayName: String {
        switch self {
        case .dailyNotes: return "Daily Notes"
        case .weeklyPlanner: return "Weekly Planner"
        case .visionBoard: return "Vision Board"
        case .calendar: return "Calendar"
        case .annualPlanner: return "Annual Planner"
        }
    }
    
    var icon: String {
        switch self {
        case .dailyNotes: return "note.text"
        case .weeklyPlanner: return "calendar"
        case .visionBoard: return "eye"
        case .calendar: return "calendar.badge.clock"
        case .annualPlanner: return "calendar.badge.plus"
        }
    }
}

