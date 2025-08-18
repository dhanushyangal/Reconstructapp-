import WidgetKit
import SwiftUI

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Annual Calendar")
        .description("Interactive calendar with events and reminders.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), currentMonth: "January", events: ["Event 1"], daysInMonth: 31)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let entry = CalendarEntry(date: Date(), currentMonth: "December", events: ["Meeting", "Birthday"], daysInMonth: 31)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Get data from shared storage
        let sharedData = SharedDataModel.getCalendarData()
        let entry = CalendarEntry(
            date: currentDate,
            currentMonth: sharedData?.currentMonth ?? "December",
            events: sharedData?.events ?? ["Calendar events"],
            daysInMonth: sharedData?.daysInMonth ?? 30
        )
        
        // Update daily at midnight
        let nextUpdate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let currentMonth: String
    let events: [String]
    let daysInMonth: Int
}

struct CalendarWidgetView: View {
    var entry: CalendarProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("Annual Calendar")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(entry.events.count)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Month and Year
            Text(entry.currentMonth)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            // Calendar Grid for larger widgets
            if family == .systemLarge {
                CalendarGridView(entry: entry)
            } else {
                // Simple view for smaller widgets
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today: \(entry.date, style: .date)")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if let firstEvent = entry.events.first {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(firstEvent)
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
                Text("\(entry.daysInMonth) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    // Deep link to calendar
                    if let url = URL(string: "reconstrect://calendar") {
                        WidgetCenter.shared.openURL(url)
                    }
                }) {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.orange)
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

struct CalendarGridView: View {
    var entry: CalendarProvider.Entry
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            // Day headers
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: 20)
            }
            
            // Calendar days (simplified)
            ForEach(1...entry.daysInMonth, id: \.self) { day in
                Text("\(day)")
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .frame(width: 25, height: 25)
                    .background(
                        Circle()
                            .fill(day == Calendar.current.component(.day, from: entry.date) ? Color.orange.opacity(0.3) : Color.clear)
                    )
            }
        }
    }
}

struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalendarWidgetView(entry: CalendarEntry(date: Date(), currentMonth: "December", events: ["Team Meeting", "Birthday Party"], daysInMonth: 31))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        CalendarWidgetView(entry: CalendarEntry(date: Date(), currentMonth: "December", events: ["Team Meeting", "Birthday Party"], daysInMonth: 31))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
