import WidgetKit
import SwiftUI

struct AnnualPlannerWidget: Widget {
    let kind: String = "AnnualPlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnnualPlannerProvider()) { entry in
            AnnualPlannerWidgetView(entry: entry)
        }
        .configurationDisplayName("Annual Planner")
        .description("Track your year goals and milestones.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AnnualPlannerEntry: TimelineEntry {
    let date: Date
    let yearGoals: [String]
    let completedMilestones: Int
    let totalMilestones: Int
    let theme: WidgetTheme
}

struct AnnualPlannerProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnnualPlannerEntry {
        AnnualPlannerEntry(date: Date(), yearGoals: ["Set your year goals"], completedMilestones: 0, totalMilestones: 0, theme: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (AnnualPlannerEntry) -> ()) {
        let currentDate = Date()
        let sharedData = SharedDataModel.getAnnualPlannerData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "AnnualPlannerWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = AnnualPlannerEntry(
            date: currentDate,
            yearGoals: sharedData?.yearGoals ?? ["Set your year goals"],
            completedMilestones: sharedData?.completedMilestones ?? 0,
            totalMilestones: sharedData?.totalMilestones ?? 0,
            theme: theme
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let sharedData = SharedDataModel.getAnnualPlannerData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "AnnualPlannerWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = AnnualPlannerEntry(
            date: currentDate,
            yearGoals: sharedData?.yearGoals ?? ["Set your year goals"],
            completedMilestones: sharedData?.completedMilestones ?? 0,
            totalMilestones: sharedData?.totalMilestones ?? 0,
            theme: theme
        )

        let nextUpdate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct AnnualPlannerWidgetView: View {
    var entry: AnnualPlannerProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(entry.theme.color)
                    .font(.title2)
                Text("Annual Planner")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.completedMilestones)/\(entry.totalMilestones)")
                    .font(.caption)
                    .foregroundColor(entry.theme.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(entry.theme.color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if family == .systemMedium {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.yearGoals.prefix(3), id: \.self) { goal in
                        Text("• \(goal)")
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text(entry.yearGoals.first ?? "Set your year goals")
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ProgressView(value: entry.totalMilestones > 0 ? Double(entry.completedMilestones) / Double(entry.totalMilestones) : 0)
                .progressViewStyle(LinearProgressViewStyle(tint: entry.theme.color))
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
            
            HStack {
                Text("Year Goals")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    if let url = URL(string: "reconstrect://annualplanner") {
                        WidgetCenter.shared.openURL(url)
                    }
                }) {
                    Image(systemName: "target")
                        .foregroundColor(entry.theme.color)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct AnnualPlannerWidget_Previews: PreviewProvider {
    static var previews: some View {
        AnnualPlannerWidgetView(entry: AnnualPlannerEntry(date: Date(), yearGoals: ["Learn new language", "Save money"], completedMilestones: 3, totalMilestones: 10, theme: .sport))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        AnnualPlannerWidgetView(entry: AnnualPlannerEntry(date: Date(), yearGoals: ["Learn new language", "Save money", "Travel abroad"], completedMilestones: 3, totalMilestones: 10, theme: .animal))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
