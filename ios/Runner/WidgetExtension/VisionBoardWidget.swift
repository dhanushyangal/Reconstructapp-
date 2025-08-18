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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct VisionBoardEntry: TimelineEntry {
    let date: Date
    let goals: [String]
    let motivation: String
    let theme: WidgetTheme
}

struct VisionBoardProvider: TimelineProvider {
    func placeholder(in context: Context) -> VisionBoardEntry {
        VisionBoardEntry(date: Date(), goals: ["Define your dreams"], motivation: "Keep dreaming big", theme: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (VisionBoardEntry) -> ()) {
        let currentDate = Date()
        let sharedData = SharedDataModel.getVisionBoardData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "VisionBoardWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = VisionBoardEntry(
            date: currentDate,
            goals: sharedData?.goals ?? ["Define your dreams"],
            motivation: sharedData?.motivation ?? "Keep dreaming big",
            theme: theme
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let sharedData = SharedDataModel.getVisionBoardData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "VisionBoardWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = VisionBoardEntry(
            date: currentDate,
            goals: sharedData?.goals ?? ["Define your dreams"],
            motivation: sharedData?.motivation ?? "Keep dreaming big",
            theme: theme
        )

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct VisionBoardWidgetView: View {
    var entry: VisionBoardProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(entry.theme.color)
                    .font(.title2)
                Text("Vision Board")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.goals.count)")
                    .font(.caption)
                    .foregroundColor(entry.theme.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(entry.theme.color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if family == .systemMedium {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.goals.prefix(3), id: \.self) { goal in
                        Text("• \(goal)")
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text(entry.motivation)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Text("Goals & Dreams")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    if let url = URL(string: "reconstrect://visionboard") {
                        WidgetCenter.shared.openURL(url)
                    }
                }) {
                    Image(systemName: "star.fill")
                        .foregroundColor(entry.theme.color)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct VisionBoardWidget_Previews: PreviewProvider {
    static var previews: some View {
        VisionBoardWidgetView(entry: VisionBoardEntry(date: Date(), goals: ["Travel the world", "Start a business"], motivation: "Dream big, work hard", theme: .premium))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        VisionBoardWidgetView(entry: VisionBoardEntry(date: Date(), goals: ["Travel the world", "Start a business", "Learn new skills"], motivation: "Dream big, work hard", theme: .watercolor))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
