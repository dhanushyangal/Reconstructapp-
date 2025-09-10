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
        let theme = SharedDataModel.getTheme()
        var categories = SharedDataModel.getCategories()
        var todosByCategory: [String: [SharedDataModel.TodoItem]] = [:]

        if let currentTheme = theme {
            for category in categories {
                if let todosJson = SharedDataModel.getTodos(for: category, theme: currentTheme) {
                    if let data = todosJson.data(using: .utf8) {
                        do {
                            let decodedTodos = try JSONDecoder().decode([SharedDataModel.TodoItem].self, from: data)
                            todosByCategory[category] = decodedTodos
                        } catch {
                            print("Failed to decode todos for \(category): \(error)")
                        }
                    }
                }
            }
        }

        let entry = VisionBoardEntry(
            date: currentDate,
            theme: theme,
            categories: categories,
            todosByCategory: todosByCategory
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // Helper to provide a default starter category based on theme
    private func defaultStarterCategory(for theme: String) -> [String] {
        switch theme {
        case "Premium Vision Board": return ["Career"]
        case "PostIt Vision Board": return ["Travel"]
        case "Ruby Reds Vision Board": return ["Love"]
        case "Winter Warmth Vision Board": return ["Family"]
        case "Coffee Hues Vision Board": return ["Health"]
        case "Box Vision Board": return ["Hobbies"]
        default: return ["Vision"]
        }
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
                if let theme = entry.theme {
                    if entry.categories.isEmpty {
                        // Theme selected but no categories yet – prompt to select categories
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.35))
                            VStack(spacing: 8) {
                                Text("Select categories")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Tap to choose up to 5 categories")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, 12)
                        .widgetURL(URL(string: "reconstrect://visionboard/category-select"))
                    } else {
                        // Show categories grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(entry.categories, id: \.self) { category in
                                CategoryBoxView(
                                    category: category,
                                    todos: entry.todosByCategory[category] ?? [],
                                    theme: theme
                                )
                                .widgetURL(URL(string: "reconstrect://visionboard/category/\(category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category)"))
                            }
                            
                            // Add category button if less than 5 categories
                            if entry.categories.count < 5 {
                                AddCategoryBoxView(theme: theme)
                                    .widgetURL(URL(string: "reconstrect://visionboard/category-select"))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    }
                } else {
                    // No theme selected - show theme selection prompt
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.35))
                        VStack(spacing: 8) {
                            Text("Select a theme to start")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Tap to choose your Vision Board theme")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(12)
                    }
                    .padding(.horizontal, 12)
                    .widgetURL(URL(string: "reconstrect://visionboard/theme"))
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

struct AddCategoryBoxView: View {
    let theme: String
    
    var body: some View {
        VStack {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)
            
            Text("Add category")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textColor)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch theme {
        case "Premium Vision Board": return Color(red: 0.2, green: 0.3, blue: 0.8).opacity(0.7)
        case "PostIt Vision Board": return Color(red: 1.0, green: 0.9, blue: 0.1).opacity(0.7)
        case "Ruby Reds Vision Board": return Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.7)
        case "Winter Warmth Vision Board": return Color(red: 0.9, green: 0.6, blue: 0.4).opacity(0.7)
        case "Coffee Hues Vision Board": return Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.7)
        case "Box Vision Board": return Color(red: 0.9, green: 0.9, blue: 0.9).opacity(0.7)
        default: return Color.blue.opacity(0.7)
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

