import WidgetKit
import SwiftUI

struct WeeklyPlannerWidget: Widget {
    let kind: String = "WeeklyPlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyPlannerProvider()) { entry in
            WeeklyPlannerWidgetView(entry: entry)
        }
        .configurationDisplayName("Weekly Planner")
        .description("Track your weekly goals and progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WeeklyPlannerEntry: TimelineEntry {
    let date: Date
    let weekGoals: [String]
    let completedTasks: Int
    let totalTasks: Int
    let theme: WidgetTheme
}

struct WeeklyPlannerProvider: TimelineProvider {
    typealias Entry = WeeklyPlannerEntry
    
    func placeholder(in context: Context) -> WeeklyPlannerEntry {
        WeeklyPlannerEntry(date: Date(), weekGoals: ["Set your weekly goals"], completedTasks: 0, totalTasks: 0, theme: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyPlannerEntry) -> ()) {
        let currentDate = Date()
        let sharedData = SharedDataModel.getWeeklyPlannerData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "WeeklyPlannerWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = WeeklyPlannerEntry(
            date: currentDate,
            weekGoals: sharedData?.weekGoals ?? ["Set your weekly goals"],
            completedTasks: sharedData?.completedTasks ?? 0,
            totalTasks: sharedData?.totalTasks ?? 0,
            theme: theme
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyPlannerEntry>) -> ()) {
        let currentDate = Date()
        let sharedData = SharedDataModel.getWeeklyPlannerData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "WeeklyPlannerWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = WeeklyPlannerEntry(
            date: currentDate,
            weekGoals: sharedData?.weekGoals ?? ["Set your weekly goals"],
            completedTasks: sharedData?.completedTasks ?? 0,
            totalTasks: sharedData?.totalTasks ?? 0,
            theme: theme
        )

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct WeeklyPlannerWidgetView: View {
    var entry: WeeklyPlannerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(entry.theme.color)
                    .font(.title2)
                Text("Weekly Planner")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.completedTasks)/\(entry.totalTasks)")
                    .font(.caption)
                    .foregroundColor(entry.theme.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(entry.theme.color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if family == .systemMedium {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.weekGoals.prefix(3), id: \.self) { goal in
                        Text("• \(goal)")
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text(entry.weekGoals.first ?? "Set your weekly goals")
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ProgressView(value: entry.totalTasks > 0 ? Double(entry.completedTasks) / Double(entry.totalTasks) : 0)
                .progressViewStyle(LinearProgressViewStyle(tint: entry.theme.color))
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
            
            HStack {
                Text("This Week")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    if let url = URL(string: "mentalfitness://weeklyplanner") {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(entry.theme.color)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct WeeklyPlannerWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyPlannerWidgetView(entry: WeeklyPlannerEntry(date: Date(), weekGoals: ["Complete project", "Exercise 3 times"], completedTasks: 2, totalTasks: 5, theme: .floral))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        WeeklyPlannerWidgetView(entry: WeeklyPlannerEntry(date: Date(), weekGoals: ["Complete project", "Exercise 3 times", "Read 2 chapters"], completedTasks: 2, totalTasks: 5, theme: .premium))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
