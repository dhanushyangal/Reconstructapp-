import WidgetKit
import SwiftUI

struct AnnualPlannerEntry: TimelineEntry {
    let date: Date
    let theme: String
    let months: [String]
    let todosByMonth: [String: [SharedDataModel.TodoItem]]
}

struct AnnualPlannerProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnnualPlannerEntry {
        AnnualPlannerEntry(
            date: Date(),
            theme: "Floral Monthly Planner",
            months: ["January", "February", "March", "April"],
            todosByMonth: [
                "January": [SharedDataModel.TodoItem(text: "Plan year", isCompleted: false)],
                "February": [SharedDataModel.TodoItem(text: "Health check", isCompleted: true)]
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AnnualPlannerEntry) -> ()) {
        let entry = buildEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AnnualPlannerEntry>) -> ()) {
        let entry = buildEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func buildEntry() -> AnnualPlannerEntry {
        let theme = SharedDataModel.getAnnualTheme()
        let allMonths = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

        var todosByMonth: [String: [SharedDataModel.TodoItem]] = [:]
        var activeMonths: [String] = []
        for month in allMonths {
            let todos = SharedDataModel.getAnnualTodos(for: month)
            if !todos.isEmpty {
                todosByMonth[month] = todos
                activeMonths.append(month)
            }
        }

        let monthsToShow = Array(activeMonths.prefix(4))
        return AnnualPlannerEntry(date: Date(), theme: theme, months: monthsToShow, todosByMonth: todosByMonth)
    }
}

struct AnnualPlannerWidgetEntryView: View {
    var entry: AnnualPlannerProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            annualBackground(for: entry.theme)
            VStack(spacing: 8) {
                HStack {
                    Text("Annual Planner")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(headerTextColor(for: entry.theme))
                    Spacer()
                    if let url = URL(string: "mentalfitness://annual-planner/add") {
                        Link(destination: url) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(headerTextColor(for: entry.theme))
                        }
                    }
                }
                .padding(.horizontal, 8)

                if entry.months.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(entry.months, id: \.self) { month in
                            monthBox(month: month, todos: entry.todosByMonth[month] ?? [], theme: entry.theme)
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
                Text("Tap + to add months")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(10)
        }
        .padding(.horizontal, 12)
    }

    private func monthBox(month: String, todos: [SharedDataModel.TodoItem], theme: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(month)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(monthTextColor(for: theme))

            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(todos.prefix(3).enumerated()), id: \.offset) { _, todo in
                    HStack(spacing: 4) {
                        Text(todo.isCompleted ? "✓" : "•")
                            .font(.system(size: 12))
                            .foregroundColor(monthTextColor(for: theme))
                        Text(todo.text)
                            .font(.system(size: 11))
                            .foregroundColor(monthTextColor(for: theme))
                            .lineLimit(1)
                    }
                }
                if todos.count > 3 {
                    Text("+\(todos.count - 3) more")
                        .font(.system(size: 10))
                        .foregroundColor(monthTextColor(for: theme).opacity(0.7))
                }
            }
            Spacer()
        }
        .padding(8)
        .frame(height: 80)
        .background(monthBackground(for: theme, month: month))
        .cornerRadius(8)
        .widgetURL(URL(string: "mentalfitness://annual-planner/month/\(month)"))
    }

    private func annualBackground(for theme: String) -> some View {
        switch true {
        case theme.contains("Premium"): return AnyView(Color.black)
        case theme.contains("PostIt"), theme.contains("Post-it"): return AnyView(Color(red: 1.0, green: 0.97, blue: 0.85))
        default: return AnyView(Color.white)
        }
    }

    private func monthBackground(for theme: String, month: String) -> Color {
        switch true {
        case theme.contains("Premium"): return Color(red: 0.12, green: 0.12, blue: 0.12)
        case theme.contains("PostIt"), theme.contains("Post-it"): return Color(red: 1.0, green: 0.9, blue: 0.6)
        case theme.contains("Watercolor"): return Color.white.opacity(0.95)
        case theme.contains("Floral"): return Color(red: 0.11, green: 0.6, blue: 0.55)
        default: return Color.white
        }
    }

    private func monthTextColor(for theme: String) -> Color {
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

struct AnnualPlannerWidget: Widget {
    let kind: String = "AnnualPlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnnualPlannerProvider()) { entry in
            AnnualPlannerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Annual Planner")
        .description("View and manage your monthly goals by month.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}


