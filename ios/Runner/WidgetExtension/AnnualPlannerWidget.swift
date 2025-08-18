import WidgetKit
import SwiftUI

struct AnnualPlannerWidget: Widget {
    let kind: String = "AnnualPlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnnualPlannerProvider()) { entry in
            AnnualPlannerWidgetView(entry: entry)
        }
        .configurationDisplayName("Annual Planner")
        .description("Plan your year with goals and milestones.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct AnnualPlannerProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnnualPlannerEntry {
        AnnualPlannerEntry(date: Date(), yearGoals: ["Goal 1", "Goal 2"], completedMilestones: 2, totalMilestones: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (AnnualPlannerEntry) -> ()) {
        let entry = AnnualPlannerEntry(date: Date(), yearGoals: ["Career Growth", "Health Goals"], completedMilestones: 5, totalMilestones: 12)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        
        // Get data from shared storage
        let sharedData = SharedDataModel.getAnnualPlannerData()
        let entry = AnnualPlannerEntry(
            date: currentDate,
            yearGoals: sharedData?.yearGoals ?? ["Your annual goals"],
            completedMilestones: sharedData?.completedMilestones ?? 0,
            totalMilestones: sharedData?.totalMilestones ?? 0
        )
        
        // Update weekly
        let nextUpdate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct AnnualPlannerEntry: TimelineEntry {
    let date: Date
    let yearGoals: [String]
    let completedMilestones: Int
    let totalMilestones: Int
}

struct AnnualPlannerWidgetView: View {
    var entry: AnnualPlannerProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Annual Planner")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.completedMilestones)/\(entry.totalMilestones)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Progress Bar
            ProgressView(value: Double(entry.completedMilestones), total: Double(entry.totalMilestones))
                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                .scaleEffect(y: 2)
            
            // Year display
            Text("\(Calendar.current.component(.year, from: entry.date))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            // Goals based on widget size
            if family == .systemSmall {
                if let firstGoal = entry.yearGoals.first {
                    Text(firstGoal)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.yearGoals.prefix(3), id: \.self) { goal in
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.red)
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
                Text("Year Goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    // Deep link to annual planner
                    if let url = URL(string: "reconstrect://annualplanner") {
                        WidgetCenter.shared.openURL(url)
                    }
                }) {
                    Image(systemName: "target.circle.fill")
                        .foregroundColor(.red)
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

struct AnnualPlannerWidget_Previews: PreviewProvider {
    static var previews: some View {
        AnnualPlannerWidgetView(entry: AnnualPlannerEntry(date: Date(), yearGoals: ["Career Growth", "Health Goals", "Financial Freedom"], completedMilestones: 5, totalMilestones: 12))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        AnnualPlannerWidgetView(entry: AnnualPlannerEntry(date: Date(), yearGoals: ["Career Growth", "Health Goals", "Financial Freedom"], completedMilestones: 5, totalMilestones: 12))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
