import WidgetKit
import SwiftUI

struct VisionBoardProvider: TimelineProvider {
    func placeholder(in context: Context) -> VisionBoardEntry {
        VisionBoardEntry(
            date: Date(),
            theme: "Premium Vision Board",
            categories: ["Career", "Health", "Travel"],
            todosByCategory: [
                "Career": [
                    SharedDataModel.TodoItem(text: "Get promoted", isCompleted: false),
                    SharedDataModel.TodoItem(text: "Learn new skills", isCompleted: true)
                ],
                "Health": [
                    SharedDataModel.TodoItem(text: "Exercise daily", isCompleted: false)
                ]
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VisionBoardEntry) -> ()) {
        let entry = VisionBoardEntry(
            date: Date(),
            theme: "Premium Vision Board",
            categories: ["Career", "Health"],
            todosByCategory: [
                "Career": [
                    SharedDataModel.TodoItem(text: "Get promoted", isCompleted: false)
                ]
            ]
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VisionBoardEntry>) -> ()) {
        let currentDate = Date()
        // Get theme - should be normalized by SharedDataModel
        let currentTheme = SharedDataModel.getTheme() ?? "Premium Vision Board"
        
        print("Vision Board Widget: Current theme = \(currentTheme)")
        
        // Get all possible vision board categories (matching Android logic)
        let allPossibleCategories = [
            "BMI", "Career", "DIY", "Family", "Food",
            "Forgive", "Health", "Help", "Hobbies",
            "Income", "Inspiration", "Invest", "Knowledge",
            "Love", "Luxury", "Music", "Reading", "Self Care",
            "Social", "Tech", "Travel"
        ]
        
        // First, check saved categories from Flutter (selected_life_areas) - these are the ones user selected
        let savedCategories = SharedDataModel.getCategories()
        print("Vision Board Widget: Saved categories = \(savedCategories)")
        
        // Only include categories that have tasks (like Android does)
        var categoriesWithTasks: [String] = []
        var todosByCategory: [String: [SharedDataModel.TodoItem]] = [:]
        
        // Priority 1: Check saved categories first (these are what user actually selected)
        for category in savedCategories {
            let todos = SharedDataModel.getVisionBoardTodos(for: category, theme: currentTheme)
            print("Vision Board Widget: Category '\(category)' has \(todos.count) todos")
            if !todos.isEmpty {
                if !categoriesWithTasks.contains(category) {
                    categoriesWithTasks.append(category)
                    todosByCategory[category] = todos
                }
            }
        }
        
        // Priority 2: Check all possible categories if we still have room (max 4)
        if categoriesWithTasks.count < 4 {
            for category in allPossibleCategories {
                if categoriesWithTasks.count >= 4 { break }
                if categoriesWithTasks.contains(category) { continue }
                
                let todos = SharedDataModel.getVisionBoardTodos(for: category, theme: currentTheme)
                if !todos.isEmpty {
                    categoriesWithTasks.append(category)
                    todosByCategory[category] = todos
                }
            }
        }
        
        print("Vision Board Widget: Found \(categoriesWithTasks.count) categories with tasks: \(categoriesWithTasks)")
        
        // Limit to 4 categories (matching Android MAX_CATEGORIES - 1)
        let categoriesToShow = Array(categoriesWithTasks.prefix(4))
        
        let entry = VisionBoardEntry(
            date: currentDate,
            theme: currentTheme,
            categories: categoriesToShow,
            todosByCategory: todosByCategory
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
}

struct VisionBoardEntry: TimelineEntry {
    let date: Date
    let theme: String?
    let categories: [String]
    let todosByCategory: [String: [SharedDataModel.TodoItem]]
}

struct VisionBoardWidgetEntryView: View {
    var entry: VisionBoardProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Solid theme background (no image)
            Rectangle()
                .fill(themeBackgroundColor(entry.theme))

            VStack(spacing: 8) {
                // Theme name header
                HStack {
                    Text(entry.theme ?? "Vision Board")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeHeaderTextColor(entry.theme))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                if entry.categories.isEmpty {
                    // No categories with tasks - show empty state
                    let isBoxTheme = (entry.theme ?? "") == "Box Vision Board"
                    let emptyTextColor = themeHeaderTextColor(entry.theme)
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isBoxTheme ? Color.black.opacity(0.1) : Color.black.opacity(0.35))
                        VStack(spacing: 8) {
                            Text("No Goals")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(emptyTextColor)
                            Text("Add goals and tap widget\nto open app")
                                .font(.system(size: 13))
                                .foregroundColor(emptyTextColor.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(12)
                    }
                    .padding(.horizontal, 12)
                    .widgetURL(URL(string: "mentalfitness://visionboard"))
                } else {
                    // Show categories grid with tasks
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(entry.categories, id: \.self) { category in
                            CategoryBoxView(
                                category: category,
                                todos: entry.todosByCategory[category] ?? [],
                                theme: entry.theme ?? "Premium Vision Board"
                            )
                            .widgetURL(URL(string: "mentalfitness://visionboard/category/\(category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category)"))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Theme Background
private func themeBackgroundColor(_ theme: String?) -> Color {
    guard let theme = theme else { return Color(red: 0.12, green: 0.12, blue: 0.12) }
    switch theme {
    case "Premium Vision Board": return Color(red: 0.2, green: 0.3, blue: 0.8)
    case "PostIt Vision Board": return Color(red: 1.0, green: 0.9, blue: 0.1)
    case "Ruby Reds Vision Board": return Color(red: 0.8, green: 0.2, blue: 0.2)
    case "Winter Warmth Vision Board": return Color(red: 0.9, green: 0.6, blue: 0.4)
    case "Coffee Hues Vision Board": return Color(red: 0.6, green: 0.4, blue: 0.2)
    case "Box Vision Board": return Color(red: 0.95, green: 0.95, blue: 0.95)
    default: return Color(red: 0.12, green: 0.12, blue: 0.12)
    }
}

// MARK: - Theme Header Text Color
private func themeHeaderTextColor(_ theme: String?) -> Color {
    guard let theme = theme else { return Color.white }
    // Box theme needs black text on light background
    if theme == "Box Vision Board" {
        return Color.black
    }
    // All other themes use white text
    return Color.white
}

struct CategoryBoxView: View {
    let category: String
    let todos: [SharedDataModel.TodoItem]
    let theme: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category title
            Text(category)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(textColor)
                .lineLimit(1)
            
            // Todo items (max 3)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(todos.prefix(3).enumerated()), id: \.offset) { index, todo in
                    HStack(spacing: 4) {
                        Text(todo.isCompleted ? "✓" : "•")
                            .font(.system(size: 12))
                            .foregroundColor(textColor)
                        
                        Text(todo.text)
                            .font(.system(size: 11))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                    }
                }
                
                if todos.count > 3 {
                    Text("+\(todos.count - 3) more")
                        .font(.system(size: 10))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(8)
        .frame(height: 80)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch theme {
        case "Premium Vision Board": return Color(red: 0.2, green: 0.3, blue: 0.8)
        case "PostIt Vision Board": return Color(red: 1.0, green: 0.9, blue: 0.1)
        case "Ruby Reds Vision Board": return Color(red: 0.8, green: 0.2, blue: 0.2)
        case "Winter Warmth Vision Board": return Color(red: 0.9, green: 0.6, blue: 0.4)
        case "Coffee Hues Vision Board": return Color(red: 0.6, green: 0.4, blue: 0.2)
        case "Box Vision Board": return Color(red: 0.9, green: 0.9, blue: 0.9)
        default: return Color.blue
        }
    }
    
    private var textColor: Color {
        switch theme {
        case "Box Vision Board": return Color.black
        default: return Color.white
        }
    }
}

struct VisionBoardWidget: Widget {
    let kind: String = "VisionBoardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VisionBoardProvider()) { entry in
            VisionBoardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Vision Board")
        .description("Track your goals and categories with your Vision Board theme.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    VisionBoardWidget()
} timeline: {
    VisionBoardEntry(
        date: .now,
        theme: "Premium Vision Board",
        categories: ["Career", "Health", "Travel"],
        todosByCategory: [
            "Career": [
                SharedDataModel.TodoItem(text: "Get promoted", isCompleted: false),
                SharedDataModel.TodoItem(text: "Learn new skills", isCompleted: true)
            ],
            "Health": [
                SharedDataModel.TodoItem(text: "Exercise daily", isCompleted: false)
            ]
        ]
    )
}

