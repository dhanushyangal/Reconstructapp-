import WidgetKit
import SwiftUI

@main
struct WidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyNotesWidget()
        WeeklyPlannerWidget()
        VisionBoardWidget()
        CalendarWidget()
        AnnualPlannerWidget()
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), widgetType: .dailyNotes, data: "Loading...")
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(date: Date(), widgetType: .dailyNotes, data: "Sample Data")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [WidgetEntry] = []
        let currentDate = Date()
        
        // Create entries for different widget types
        let widgetTypes: [WidgetType] = [.dailyNotes, .weeklyPlanner, .visionBoard, .calendar, .annualPlanner]
        
        for (index, widgetType) in widgetTypes.enumerated() {
            let entryDate = Calendar.current.date(byAdding: .minute, value: index * 30, to: currentDate)!
            let entry = WidgetEntry(date: entryDate, widgetType: widgetType, data: "Widget Data")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let widgetType: WidgetType
    let data: String
}

enum WidgetType: String, CaseIterable {
    case dailyNotes = "Daily Notes"
    case weeklyPlanner = "Weekly Planner"
    case visionBoard = "Vision Board"
    case calendar = "Calendar"
    case annualPlanner = "Annual Planner"
}

struct WidgetBundleEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch entry.widgetType {
        case .dailyNotes:
            DailyNotesWidgetView(entry: entry)
        case .weeklyPlanner:
            WeeklyPlannerWidgetView(entry: entry)
        case .visionBoard:
            VisionBoardWidgetView(entry: entry)
        case .calendar:
            CalendarWidgetView(entry: entry)
        case .annualPlanner:
            AnnualPlannerWidgetView(entry: entry)
        }
    }
}

struct DailyNotesWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.blue)
                Text("Daily Notes")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text(entry.data)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct WeeklyPlannerWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                Text("Weekly Planner")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text(entry.data)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Text("This Week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "list.bullet")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct VisionBoardWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.purple)
                Text("Vision Board")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text(entry.data)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Text("Goals & Dreams")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "star")
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct CalendarWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                Text("Annual Calendar")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text(entry.data)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct AnnualPlannerWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.red)
                Text("Annual Planner")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text(entry.data)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Text("Year Goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "target")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct WidgetBundle_Previews: PreviewProvider {
    static var previews: some View {
        WidgetBundleEntryView(entry: WidgetEntry(date: Date(), widgetType: .dailyNotes, data: "Preview Data"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
