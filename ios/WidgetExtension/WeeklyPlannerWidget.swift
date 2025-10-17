import WidgetKit
import SwiftUI

struct WeeklyPlannerEntry: TimelineEntry {
    let date: Date
    let theme: String
    let days: [String]
    let todosByDay: [String: [SharedDataModel.TodoItem]]
}

struct WeeklyPlannerProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyPlannerEntry {
        WeeklyPlannerEntry(
            date: Date(),
            theme: "Floral Weekly Planner",
            days: ["Monday", "Tuesday", "Wednesday", "Thursday"],
            todosByDay: [
                "Monday": [SharedDataModel.TodoItem(text: "Plan week", isCompleted: false)],
                "Tuesday": [SharedDataModel.TodoItem(text: "Workout", isCompleted: true)]
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyPlannerEntry) -> ()) {
        let entry = buildEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyPlannerEntry>) -> ()) {
        let entry = buildEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func buildEntry() -> WeeklyPlannerEntry {
        let theme = SharedDataModel.getWeeklyTheme()
        let allDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        // Read todos and only include days that have tasks
        var todosByDay: [String: [SharedDataModel.TodoItem]] = [:]
        var activeDays: [String] = []
        for day in allDays {
            let todos = SharedDataModel.getWeeklyTodos(for: day)
            if !todos.isEmpty {
                todosByDay[day] = todos
                activeDays.append(day)
            }
        }

        // Limit to 4 days as in Android UI
        let daysToShow = Array(activeDays.prefix(4))
        return WeeklyPlannerEntry(date: Date(), theme: theme, days: daysToShow, todosByDay: todosByDay)
    }
}

struct WeeklyPlannerWidgetEntryView: View {
    var entry: WeeklyPlannerProvider.Entry
    @Environment(\.
        widgetFamily) var family

    var body: some View {
        ZStack {
            weeklyBackground(for: entry.theme)
            VStack(spacing: 8) {
                HStack {
                    Text("Weekly Planner")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(headerTextColor(for: entry.theme))
                    Spacer()
                    if let url = URL(string: "mentalfitness://weekly-planner/add") {
                        Link(destination: url) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(headerTextColor(for: entry.theme))
                        }
                    }
                }
                .padding(.horizontal, 8)

                if entry.days.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(entry.days, id: \.self) { day in
                            dayBox(day: day, todos: entry.todosByDay[day] ?? [], theme: entry.theme)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 8)
        }
        .containerBackground(.clear, for: .widget)
    }

    private var emptyState: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.35))
            VStack(spacing: 6) {
                Text("No Goals")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text("Tap + to add days")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(10)
        }
        .padding(.horizontal, 12)
    }

    private func dayBox(day: String, todos: [SharedDataModel.TodoItem], theme: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(dayTextColor(for: theme))

            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(todos.prefix(3).enumerated()), id: \.offset) { _, todo in
                    HStack(spacing: 4) {
                        Text(todo.isCompleted ? "✓" : "•")
                            .font(.system(size: 12))
                            .foregroundColor(dayTextColor(for: theme))
                        Text(todo.text)
                            .font(.system(size: 11))
                            .foregroundColor(dayTextColor(for: theme))
                            .lineLimit(1)
                    }
                }
                if todos.count > 3 {
                    Text("+\(todos.count - 3) more")
                        .font(.system(size: 10))
                        .foregroundColor(dayTextColor(for: theme).opacity(0.7))
                }
            }
            Spacer()
        }
        .padding(8)
        .frame(height: 80)
        .background(dayBackground(for: theme))
        .cornerRadius(8)
        .widgetURL(URL(string: "mentalfitness://weekly-planner/day/\(day)"))
    }

    private func weeklyBackground(for theme: String) -> some View {
        switch theme {
        case _ where theme.contains("Premium"): return AnyView(Color.black)
        default: return AnyView(Color(red: 0.98, green: 0.95, blue: 0.90))
        }
    }

    private func dayBackground(for theme: String) -> Color {
        switch true {
        case theme.contains("Premium"): return Color(red: 0.12, green: 0.12, blue: 0.12)
        case theme.contains("PostIt"), theme.contains("Post-it"): return Color(red: 1.0, green: 0.9, blue: 0.6)
        case theme.contains("Watercolor"): return Color.white.opacity(0.95)
        case theme.contains("Floral"): return Color(red: 0.11, green: 0.6, blue: 0.55)
        default: return Color.white
        }
    }

    private func dayTextColor(for theme: String) -> Color {
        switch true {
        case theme.contains("Premium"): return .white
        case theme.contains("Floral"): return .white
        default: return .black
        }
    }

    private func headerTextColor(for theme: String) -> Color {
        switch true {
        case theme.contains("Premium"): return .white
        default: return .black
        }
    }
}

struct WeeklyPlannerWidget: Widget {
    let kind: String = "WeeklyPlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyPlannerProvider()) { entry in
            WeeklyPlannerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weekly Planner")
        .description("View and manage your weekly goals by day.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}


