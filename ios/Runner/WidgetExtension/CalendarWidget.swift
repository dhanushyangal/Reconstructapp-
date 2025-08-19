import WidgetKit
import SwiftUI

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("View your calendar and events.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let events: [String]
    let currentMonth: String
    let daysInMonth: Int
    let theme: WidgetTheme
}

struct CalendarProvider: TimelineProvider {
    typealias Entry = CalendarEntry
    
    func placeholder(in context: Context) -> CalendarEntry {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let currentMonth = monthFormatter.string(from: Date())
        
        return CalendarEntry(date: Date(), events: ["No events"], currentMonth: currentMonth, daysInMonth: 30, theme: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let currentDate = Date()
        let sharedData = SharedDataModel.getCalendarData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "CalendarWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = CalendarEntry(
            date: currentDate,
            events: sharedData?.events ?? ["No events"],
            currentMonth: sharedData?.currentMonth ?? "January",
            daysInMonth: sharedData?.daysInMonth ?? 30,
            theme: theme
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> ()) {
        let currentDate = Date()
        let sharedData = SharedDataModel.getCalendarData()
        let widgetConfig = SharedDataModel.getWidgetConfiguration(widgetId: "CalendarWidget")
        let theme = WidgetTheme(rawValue: widgetConfig?.theme ?? "default") ?? .default
        
        let entry = CalendarEntry(
            date: currentDate,
            events: sharedData?.events ?? ["No events"],
            currentMonth: sharedData?.currentMonth ?? "January",
            daysInMonth: sharedData?.daysInMonth ?? 30,
            theme: theme
        )

        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CalendarWidgetView: View {
    var entry: CalendarEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(entry.theme.color)
                    .font(.title2)
                Text("Calendar")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.events.count)")
                    .font(.caption)
                    .foregroundColor(entry.theme.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(entry.theme.color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if family == .systemMedium {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.events.prefix(3), id: \.self) { event in
                        Text("• \(event)")
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text(entry.currentMonth)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    if let url = URL(string: "mentalfitness://calendar") {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }) {
                    Image(systemName: "calendar")
                        .foregroundColor(entry.theme.color)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalendarWidgetView(entry: CalendarEntry(date: Date(), events: ["Team meeting", "Doctor appointment"], currentMonth: "December", daysInMonth: 31, theme: .japanese))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        CalendarWidgetView(entry: CalendarEntry(date: Date(), events: ["Team meeting", "Doctor appointment", "Dinner with friends"], currentMonth: "December", daysInMonth: 31, theme: .coffee))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
