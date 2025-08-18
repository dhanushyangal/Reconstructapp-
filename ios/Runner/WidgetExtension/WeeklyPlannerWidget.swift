import WidgetKit
import SwiftUI

struct WeeklyPlannerWidget: Widget {
    let kind: String = "WeeklyPlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyPlannerProvider()) { entry in
            WeeklyPlannerWidgetView(entry: entry)
        }
        .configurationDisplayName("Weekly Planner")
        .description("Plan your week with goals and tasks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WeeklyPlannerProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyPlannerEntry {
        WeeklyPlannerEntry(date: Date(), weekGoals: ["Goal 1", "Goal 2"], completedTasks: 2, totalTasks: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyPlannerEntry) -> ()) {
        let entry = WeeklyPlannerEntry(date: Date(), weekGoals: ["Complete project", "Exercise 3 times"], completedTasks: 3, totalTasks: 7)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        
        // Get data from shared storage
        let sharedData = SharedDataModel.getWeeklyPlannerData()
        let entry = WeeklyPlannerEntry(
            date: currentDate,
            weekGoals: sharedData?.weekGoals ?? ["Weekly planning in progress"],
            completedTasks: sharedData?.completedTasks ?? 0,
            totalTasks: sharedData?.totalTasks ?? 0
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct WeeklyPlannerEntry: TimelineEntry {
    let date: Date
    let weekGoals: [String]
    let completedTasks: Int
    let totalTasks: Int
}

struct WeeklyPlannerWidgetView: View {
    var entry: WeeklyPlannerProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Weekly Planner")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.completedTasks)/\(entry.totalTasks)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Progress Bar
            ProgressView(value: Double(entry.completedTasks), total: Double(entry.totalTasks))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(y: 2)
            
            // Content based on widget size
            if family == .systemSmall {
                if let firstGoal = entry.weekGoals.first {
                    Text(firstGoal)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.weekGoals.prefix(3), id: \.self) { goal in
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(goal)
                                .font(.body)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text("Week of \(entry.date, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    // Deep link to weekly planner
                    if let url = URL(string: "reconstrect://weeklyplanner") {
                        WidgetCenter.shared.openURL(url)
                    }
                }) {
                    Image(systemName: "list.bullet.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct WeeklyPlannerWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyPlannerWidgetView(entry: WeeklyPlannerEntry(date: Date(), weekGoals: ["Complete project", "Exercise 3 times", "Read 2 chapters"], completedTasks: 3, totalTasks: 7))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        WeeklyPlannerWidgetView(entry: WeeklyPlannerEntry(date: Date(), weekGoals: ["Complete project", "Exercise 3 times", "Read 2 chapters"], completedTasks: 3, totalTasks: 7))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
