import WidgetKit
import SwiftUI

struct VisionBoardWidget: Widget {
    let kind: String = "VisionBoardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VisionBoardProvider()) { entry in
            VisionBoardWidgetView(entry: entry)
        }
        .configurationDisplayName("Vision Board")
        .description("Visualize your goals and dreams.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct VisionBoardProvider: TimelineProvider {
    func placeholder(in context: Context) -> VisionBoardEntry {
        VisionBoardEntry(date: Date(), goals: ["Goal 1", "Goal 2"], motivation: "Stay focused on your dreams")
    }

    func getSnapshot(in context: Context, completion: @escaping (VisionBoardEntry) -> ()) {
        let entry = VisionBoardEntry(date: Date(), goals: ["Financial Freedom", "Healthy Lifestyle"], motivation: "Every day is a new opportunity")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        
        // Get data from shared storage
        let sharedData = SharedDataModel.getVisionBoardData()
        let entry = VisionBoardEntry(
            date: currentDate,
            goals: sharedData?.goals ?? ["Your vision board goals"],
            motivation: sharedData?.motivation ?? "Keep dreaming big"
        )
        
        // Update every 2 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct VisionBoardEntry: TimelineEntry {
    let date: Date
    let goals: [String]
    let motivation: String
}

struct VisionBoardWidgetView: View {
    var entry: VisionBoardProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Vision Board")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.goals.count)")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Motivation Quote
            Text(entry.motivation)
                .font(.caption)
                .italic()
                .foregroundColor(.purple)
                .lineLimit(2)
            
            // Goals based on widget size
            if family == .systemSmall {
                if let firstGoal = entry.goals.first {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text(firstGoal)
                            .font(.body)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.goals.prefix(3), id: \.self) { goal in
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.purple)
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
                Text("Dreams & Goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    // Deep link to vision board
                    if let url = URL(string: "reconstrect://visionboard") {
                        WidgetCenter.shared.openURL(url)
                    }
                }) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct VisionBoardWidget_Previews: PreviewProvider {
    static var previews: some View {
        VisionBoardWidgetView(entry: VisionBoardEntry(date: Date(), goals: ["Financial Freedom", "Healthy Lifestyle", "Career Growth"], motivation: "Every day is a new opportunity to chase your dreams"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        VisionBoardWidgetView(entry: VisionBoardEntry(date: Date(), goals: ["Financial Freedom", "Healthy Lifestyle", "Career Growth"], motivation: "Every day is a new opportunity to chase your dreams"))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
