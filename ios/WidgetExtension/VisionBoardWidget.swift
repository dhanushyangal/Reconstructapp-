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
        print("Vision Board Widget: Current theme = \(currentTheme)")
        
        // Get categories that have todos (from Flutter data)
        var categories = SharedDataModel.getCategoriesWithTodos()
        print("Vision Board Widget: Found \(categories.count) categories with todos: \(categories)")
        
        var todosByCategory: [String: [SharedDataModel.TodoItem]] = [:]
 
        // Load todos for each category using Flutter's universal storage
        for category in categories {
            let todos = SharedDataModel.getVisionBoardTodos(for: category)
            print("Vision Board Widget: Category '\(category)' has \(todos.count) todos")
            if !todos.isEmpty {
                todosByCategory[category] = todos
            }
        }

        // Limit to 5 categories max
        let maxCategories = min(5, categories.count)
        let categoriesToShow = Array(categories.prefix(maxCategories))
        let filteredTodosByCategory = categoriesToShow.reduce(into: [String: [SharedDataModel.TodoItem]]()) { result, category in
            if let todos = todosByCategory[category], !todos.isEmpty {
                result[category] = todos
            }
        }
        
        print("Vision Board Widget: Returning entry with \(categoriesToShow.count) categories, \(filteredTodosByCategory.count) with todos")

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
                // Theme name header at the top
                HStack {
                    Text(entry.theme ?? "Vision Board")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
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
                    // Only show categories that actually have todos
                    let categoriesWithTodos = entry.categories.filter { category in
                        let todos = entry.todosByCategory[category] ?? []
                        return !todos.isEmpty
                    }
                    
                    if categoriesWithTodos.isEmpty {
                        // Fallback: show empty state even if categories exist but no todos
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
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                            ForEach(Array(categoriesWithTodos.enumerated()), id: \.element) { index, category in
                                CategoryBoxView(
                                    category: category,
                                    todos: entry.todosByCategory[category] ?? [],
                                    theme: entry.theme ?? "Premium Vision Board",
                                    index: index
                                )
                                .widgetURL(URL(string: "mentalfitness://visionboard/category/\(category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category)"))
                            }
                        }
                        .padding(.horizontal, 12)
                    }
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
    let index: Int
    
    var body: some View {
        ZStack {
            // Background: image for Box theme, color for others
            if isBoxTheme {
                // Box theme - use image background with white fallback
                ZStack {
                    Color.white // Fallback background
                    Image("vision-board-ruled")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 80)
                        .clipped()
                }
                .cornerRadius(8)
            } else {
                // Other themes - use color background
                backgroundColor
                    .cornerRadius(8)
            }
            
            // Content overlay
            VStack(alignment: .leading, spacing: 6) {
                // Category title
                Text(category)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                
                // Todo items (max 3)
                VStack(alignment: .leading, spacing: 2) {
                    if todos.isEmpty {
                        Text("No tasks")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.6))
                            .lineLimit(1)
                    } else {
                        // Safely get up to 3 todos
                        let todosToShow = Array(todos.prefix(min(3, todos.count)))
                        ForEach(Array(todosToShow.enumerated()), id: \.offset) { _, todo in
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
                        
                        // Show remaining count if more than 3
                        let remaining = todos.count - 3
                        if remaining > 0 {
                            Text("+\(remaining) more")
                                .font(.system(size: 10))
                                .foregroundColor(textColor.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(8)
            .frame(height: 80)
        }
    }
    
    private var isBoxTheme: Bool {
        let lowercased = theme.lowercased()
        return lowercased.contains("box") && !lowercased.contains("ruby")
    }
    
    private var backgroundColor: Color {
        let lowercased = theme.lowercased()
        
        // Premium theme - black background with white text
        if lowercased.contains("premium") {
            return Color.black
        }
        
        // Post-it theme - colorful cards cycling through colors
        if lowercased.contains("postit") || lowercased.contains("post-it") || lowercased.contains("post it") {
            let postItColors: [Color] = [
                Color(red: 1.0, green: 0.65, blue: 0.0), // Orange
                Color(red: 0.957, green: 0.463, blue: 0.557), // Pink (244, 118, 142)
                Color(red: 0.922, green: 0.769, blue: 0.373), // Yellow (235, 196, 95)
                Color(red: 0.216, green: 0.306, blue: 0.192), // Dark green (55, 78, 49)
                Color(red: 0.643, green: 0.859, blue: 0.459), // Light green (164, 219, 117)
                Color(red: 0.667, green: 0.933, blue: 0.851), // Cyan (170, 238, 217)
                Color(red: 0.251, green: 0.325, blue: 0.635), // Blue (64, 83, 162)
                Color(red: 0.384, green: 0.494, blue: 0.541), // Blue-grey (98, 126, 138)
                Color(red: 0.263, green: 0.553, blue: 0.800), // Light blue (67, 141, 204)
            ]
            return postItColors[index % postItColors.count]
        }
        
        // Floral/Winter Warmth theme
        if lowercased.contains("winter warmth") || lowercased.contains("floral") {
            let floralColors: [Color] = [
                Color(red: 0.761, green: 0.718, blue: 0.639), // (194, 183, 163)
                Color(red: 0.200, green: 0.059, blue: 0.059), // (51, 15, 15) #330f0f
                Color(red: 0.718, green: 0.549, blue: 0.337), // (183, 140, 86) #b78c56
                Color(red: 0.176, green: 0.161, blue: 0.0), // (45, 41, 0)
                Color(red: 0.573, green: 0.565, blue: 0.573), // (146, 144, 146) #929092
                Color(red: 0.455, green: 0.067, blue: 0.008), // (113, 17, 2) #741102
                Color(red: 0.620, green: 0.549, blue: 0.400), // (158, 140, 102) #9e8c66
                Color(red: 0.275, green: 0.165, blue: 0.098), // (70, 42, 25) #462a19
                Color(red: 0.573, green: 0.573, blue: 0.455), // (146, 146, 116) #929274
            ]
            return floralColors[index % floralColors.count]
        }
        
        // Ruby Reds theme
        if lowercased.contains("ruby red") || lowercased.contains("ruby reds") {
            let rubyColors: [Color] = [
                Color(red: 0.290, green: 0.016, blue: 0.016), // #4A0404
                Color(red: 0.545, green: 0.0, blue: 0.0), // #8B0000
                Color(red: 0.663, green: 0.106, blue: 0.051), // #A91B0D
                Color(red: 0.698, green: 0.133, blue: 0.133), // #B22222
                Color(red: 0.769, green: 0.118, blue: 0.227), // #C41E3A
                Color(red: 0.863, green: 0.078, blue: 0.235), // #DC143C
                Color(red: 0.890, green: 0.259, blue: 0.204), // #E34234
                Color(red: 0.804, green: 0.361, blue: 0.361), // #CD5C5C
                Color(red: 0.890, green: 0.365, blue: 0.416), // #E35D6A
                Color(red: 1.0, green: 0.420, blue: 0.420), // #FF6B6B
            ]
            return rubyColors[index % rubyColors.count]
        }
        
        // Coffee Hues theme
        if lowercased.contains("coffee") {
            let coffeeColors: [Color] = [
                Color(red: 0.235, green: 0.165, blue: 0.129), // #3C2A21
                Color(red: 0.463, green: 0.325, blue: 0.255), // #765341
                Color(red: 0.745, green: 0.663, blue: 0.608), // #BEA99B
                Color(red: 0.961, green: 0.902, blue: 0.827), // #F5E6D3
                Color(red: 0.545, green: 0.349, blue: 0.243), // #8B593E
                Color(red: 0.824, green: 0.706, blue: 0.549), // #D2B48C
                Color(red: 0.745, green: 0.608, blue: 0.482), // #BE9B7B
                Color(red: 0.435, green: 0.306, blue: 0.216), // #6F4E37
                Color(red: 0.871, green: 0.722, blue: 0.529), // #DEB887
            ]
            return coffeeColors[index % coffeeColors.count]
        }
        
        // Default fallback
        return Color(red: 0.9, green: 0.9, blue: 0.9)
    }
    
    private var textColor: Color {
        let lowercased = theme.lowercased()
        
        // Box theme - black text
        if lowercased.contains("box") && !lowercased.contains("ruby") {
            return Color.black
        }
        
        // Post-it theme - black text
        if lowercased.contains("postit") || lowercased.contains("post-it") || lowercased.contains("post it") {
            return Color.black
        }
        
        // All other themes - white text
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

