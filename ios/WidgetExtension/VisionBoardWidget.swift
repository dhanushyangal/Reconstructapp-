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
        let currentDate = Date()
        let entry = buildEntry(date: currentDate)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VisionBoardEntry>) -> ()) {
        let currentDate = Date()
        let entry = buildEntry(date: currentDate)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // Build entry by reading shared data (like Notes widget)
    private func buildEntry(date: Date) -> VisionBoardEntry {
        // Get theme from Flutter (with fallback)
        let currentTheme = SharedDataModel.getTheme() ?? "Premium Vision Board"
        
        // Get categories that have todos (from Flutter data)
        var categories = SharedDataModel.getCategoriesWithTodos()
        var todosByCategory: [String: [SharedDataModel.TodoItem]] = [:]

        // Load todos for each category using Flutter's universal storage
        for category in categories {
            let todos = SharedDataModel.getVisionBoardTodos(for: category)
            if !todos.isEmpty {
                todosByCategory[category] = todos
            }
        }

        // Limit to 4 categories max (matching Android)
        let categoriesToShow = Array(categories.prefix(4))
        let filteredTodosByCategory = categoriesToShow.reduce(into: [String: [SharedDataModel.TodoItem]]()) { result, category in
            if let todos = todosByCategory[category] {
                result[category] = todos
            }
        }

        return VisionBoardEntry(
            date: date,
            theme: currentTheme,
            categories: categoriesToShow,
            todosByCategory: filteredTodosByCategory
        )
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
            // Theme-based background (like Notes widget)
            themeBackground(for: entry.theme)
            
            let textColor = themeTextColor(for: entry.theme)

            VStack(spacing: 8) {
                if entry.categories.isEmpty {
                    // No categories with data - show empty state
                    VStack(spacing: 8) {
                        Text("No Goals")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textColor)
                        Text("Add goals in app\nto see them here")
                            .font(.system(size: 13))
                            .foregroundColor(textColor.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .widgetURL(URL(string: "mentalfitness://visionboard"))
                } else {
                    // Show categories grid with data
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
            .padding(.vertical, 8)
        }
        .containerBackground(.clear, for: .widget)
    }
    
    // Theme-based background (like Notes widget)
    @ViewBuilder
    private func themeBackground(for theme: String?) -> some View {
        if let theme = theme {
            let lowercased = theme.lowercased()
            if lowercased.contains("premium") {
                Color(red: 0.2, green: 0.3, blue: 0.8)
            } else if lowercased.contains("postit") || lowercased.contains("post-it") || lowercased.contains("post it") {
                Color(red: 1.0, green: 0.9, blue: 0.1)
            } else if lowercased.contains("ruby red") {
                Color(red: 0.8, green: 0.2, blue: 0.2)
            } else if lowercased.contains("winter warmth") || lowercased.contains("floral") {
                Color(red: 0.9, green: 0.6, blue: 0.4)
            } else if lowercased.contains("coffee") {
                Color(red: 0.6, green: 0.4, blue: 0.2)
            } else if lowercased.contains("box") {
                Color(red: 0.95, green: 0.95, blue: 0.95)
            } else {
                Color(red: 0.12, green: 0.12, blue: 0.12)
            }
        } else {
            Color(red: 0.12, green: 0.12, blue: 0.12)
        }
    }
    
    // Theme-based text color (like Notes widget)
    private func themeTextColor(for theme: String?) -> Color {
        guard let theme = theme else { return .white }
        let lowercased = theme.lowercased()
        if lowercased.contains("box") {
            return Color(red: 0.13, green: 0.13, blue: 0.13) // Dark text on light background
        }
        return .white // White text on colored/dark backgrounds
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
        let lowercased = theme.lowercased()
        if lowercased.contains("premium") {
            return Color(red: 0.2, green: 0.3, blue: 0.8)
        } else if lowercased.contains("postit") || lowercased.contains("post-it") || lowercased.contains("post it") {
            return Color(red: 1.0, green: 0.9, blue: 0.1)
        } else if lowercased.contains("ruby red") {
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        } else if lowercased.contains("winter warmth") || lowercased.contains("floral") {
            return Color(red: 0.9, green: 0.6, blue: 0.4)
        } else if lowercased.contains("coffee") {
            return Color(red: 0.6, green: 0.4, blue: 0.2)
        } else if lowercased.contains("box") {
            return Color(red: 0.9, green: 0.9, blue: 0.9)
        }
        return Color.blue
    }
    
    private var textColor: Color {
        let lowercased = theme.lowercased()
        if lowercased.contains("box") {
            return Color.black
        }
        return Color.white
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
        let lowercased = theme.lowercased()
        if lowercased.contains("premium") {
            return Color(red: 0.2, green: 0.3, blue: 0.8).opacity(0.7)
        } else if lowercased.contains("postit") || lowercased.contains("post-it") || lowercased.contains("post it") {
            return Color(red: 1.0, green: 0.9, blue: 0.1).opacity(0.7)
        } else if lowercased.contains("ruby red") {
            return Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.7)
        } else if lowercased.contains("winter warmth") || lowercased.contains("floral") {
            return Color(red: 0.9, green: 0.6, blue: 0.4).opacity(0.7)
        } else if lowercased.contains("coffee") {
            return Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.7)
        } else if lowercased.contains("box") {
            return Color(red: 0.9, green: 0.9, blue: 0.9).opacity(0.7)
        }
        return Color.blue.opacity(0.7)
    }
    
    private var textColor: Color {
        let lowercased = theme.lowercased()
        if lowercased.contains("box") {
            return Color.black
        }
        return Color.white
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

