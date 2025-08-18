import WidgetKit
import SwiftUI

struct DailyNotesWidget: Widget {
    let kind: String = "DailyNotesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyNotesProvider()) { entry in
            DailyNotesWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Notes")
        .description("Quick access to your daily notes and thoughts.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyNotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyNotesEntry {
        DailyNotesEntry(date: Date(), noteText: "Loading your daily notes...", noteCount: 0, theme: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyNotesEntry) -> ()) {
        let entry = DailyNotesEntry(date: Date(), noteText: "Today's thoughts and reflections...", noteCount: 3, theme: .default)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        
        // Get data from shared storage
        let sharedData = SharedDataModel.getDailyNotesData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "DailyNotesWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = DailyNotesEntry(
            date: currentDate,
            noteText: sharedData?.noteText ?? "Your daily notes will appear here",
            noteCount: sharedData?.noteCount ?? 0,
            theme: theme
        )
        
        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct DailyNotesEntry: TimelineEntry {
    let date: Date
    let noteText: String
    let noteCount: Int
    let theme: WidgetTheme
}

struct DailyNotesWidgetView: View {
    var entry: DailyNotesProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(entry.theme.color)
                    .font(.title2)
                Text("Daily Notes")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.noteCount)")
                    .font(.caption)
                    .foregroundColor(entry.theme.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(entry.theme.color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Content
            if family == .systemSmall {
                Text(entry.noteText)
                    .font(.body)
                    .lineLimit(4)
                    .foregroundColor(.secondary)
            } else {
                Text(entry.noteText)
                    .font(.body)
                    .lineLimit(6)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    // Deep link to daily notes
                    if let url = URL(string: "reconstrect://dailynotes") {
                        WidgetCenter.shared.openURL(url)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(entry.theme.color)
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

struct DailyNotesWidget_Previews: PreviewProvider {
    static var previews: some View {
        DailyNotesWidgetView(entry: DailyNotesEntry(date: Date(), noteText: "Today I'm feeling grateful for...", noteCount: 5, theme: .postit))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        DailyNotesWidgetView(entry: DailyNotesEntry(date: Date(), noteText: "Today I'm feeling grateful for the beautiful weather and the opportunity to work on my goals. I want to focus on being more present and mindful throughout the day.", noteCount: 5, theme: .premium))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
