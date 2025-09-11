import WidgetKit
import SwiftUI

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(
            date: Date(),
            monthName: "September",
            year: 2025,
            selectedDates: [:],
            currentDay: 10
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let entry = CalendarEntry(
            date: Date(),
            monthName: "September",
            year: 2025,
            selectedDates: ["2025-09-10": "Personal", "2025-09-15": "Professional"],
            currentDay: 10
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> ()) {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Get current month and year
        let month = calendar.component(.month, from: currentDate)
        let year = calendar.component(.year, from: currentDate)
        let day = calendar.component(.day, from: currentDate)
        
        // Get month name
        let monthName = getMonthName(month)
        
        // Get calendar data from SharedDataModel
        let selectedDates = SharedDataModel.getCalendarData()
        
        let entry = CalendarEntry(
            date: currentDate,
            monthName: monthName,
            year: year,
            selectedDates: selectedDates,
            currentDay: day
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getMonthName(_ month: Int) -> String {
        let months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        return months[month - 1]
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let monthName: String
    let year: Int
    let selectedDates: [String: String]
    let currentDay: Int
}

struct CalendarWidgetEntryView: View {
    var entry: CalendarProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Summer theme background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.4), // Light orange
                    Color(red: 0.9, green: 0.6, blue: 0.2)  // Darker orange
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                // Top section with month/year and add button (deep link)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.monthName) \(entry.year)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Add button (opens app to add event)
                    if let url = URL(string: "mentalfitness://calendar/add?month=\(getMonthNumber(entry.monthName))&year=\(entry.year)") {
                        Link(destination: url) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            Spacer()
            
                // Calendar grid
                VStack(spacing: 4) {
                    // Day headers
                    HStack(spacing: 0) {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // Calendar days
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                        ForEach(1...30, id: \.self) { day in
                            CalendarDayView(
                                day: day,
                                isCurrentDay: day == entry.currentDay,
                                category: getCategoryForDay(day),
                                month: getMonthNumber(entry.monthName),
                                year: entry.year
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.bottom, 8)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
    
    private func getCategoryForDay(_ day: Int) -> String? {
        let month = getMonthNumber(entry.monthName)
        let dateString = String(format: "%d-%02d-%02d", entry.year, month, day)
        return entry.selectedDates[dateString]
    }
    
    private func getMonthNumber(_ monthName: String) -> Int {
        let months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        return (months.firstIndex(of: monthName) ?? 0) + 1
    }
}

struct CalendarDayView: View {
    let day: Int
    let isCurrentDay: Bool
    let category: String?
    let month: Int
    let year: Int
    
    var body: some View {
        Group {
            if let url = URL(string: "mentalfitness://calendar/day?day=\(day)&month=\(month)&year=\(year)") {
                Link(destination: url) {
                    Text("\(day)")
                        .font(.system(size: 12, weight: isCurrentDay ? .bold : .medium))
                        .foregroundColor(textColor)
                        .frame(width: 24, height: 24)
                        .background(backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            } else {
                Text("\(day)")
                    .font(.system(size: 12, weight: isCurrentDay ? .bold : .medium))
                    .foregroundColor(textColor)
                    .frame(width: 24, height: 24)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
    
    private var backgroundColor: Color {
        if let category = category {
            return getCategoryColor(category)
        } else if isCurrentDay {
            return Color.blue.opacity(0.8)
        } else {
            return Color.white.opacity(0.9)
        }
    }
    
    private var textColor: Color {
        if category != nil || isCurrentDay {
            return .white
        } else {
            return .black
        }
    }
    
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "Personal": return Color(red: 1.0, green: 0.44, blue: 0.38) // Coral
        case "Professional": return Color(red: 0.11, green: 0.6, blue: 0.55) // Teal
        case "Finance": return Color(red: 0.99, green: 0.86, blue: 0.23) // Yellow
        case "Health": return Color(red: 0.51, green: 0.38, blue: 0.76) // Purple
        default: return Color.blue
        }
    }
}

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Summer Calendar")
        .description("View your summer theme calendar with events and tasks.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    CalendarWidget()
} timeline: {
    CalendarEntry(
        date: .now,
        monthName: "September",
        year: 2025,
        selectedDates: [
            "2025-09-10": "Personal",
            "2025-09-15": "Professional",
            "2025-09-20": "Health"
        ],
        currentDay: 10
    )
}
