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
        GeometryReader { proxy in
            let topHeight = proxy.size.height * 0.4
            let bottomHeight = proxy.size.height * 0.6
            VStack(spacing: 0) {
                // Top 40% – month image with + button
                ZStack(alignment: .topTrailing) {
                    monthImageView
                        .frame(height: topHeight)
                        .clipped()
                    if let url = URL(string: "mentalfitness://calendar/add?month=\(getMonthNumber(entry.monthName))&year=\(entry.year)") {
                        Link(destination: url) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 26, height: 26)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        .padding(8)
                    }
                }

                // Bottom 60% – header + calendar grid
                ZStack {
                    Color.white
                    VStack(spacing: 6) {
                        Text("\(entry.monthName) \(entry.year)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(.darkGray))

                        // Day headers
                        HStack(spacing: 0) {
                            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(.darkGray))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 8)

                        calendarGrid
                            .padding(.horizontal, 8)
                    }
                }
                .frame(height: bottomHeight)
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

// MARK: - Subviews & Helpers
extension CalendarWidgetEntryView {
    private var monthImageView: some View {
        let month = getMonthNumber(entry.monthName)
        // Expect assets named: summer1 ... summer12
        let imageName = "summer\(month)"
        return Group {
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.76, blue: 0.36),
                        Color(red: 0.93, green: 0.60, blue: 0.24)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var calendarGrid: some View {
        let month = getMonthNumber(entry.monthName)
        let year = entry.year
        let totalDays = daysIn(month: month, year: year)
        let firstOffset = firstWeekdayOffset(month: month, year: year)

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            // Leading blanks
            ForEach(0..<firstOffset, id: \.self) { _ in
                Color.clear
                    .frame(height: 24)
            }
            // Days
            ForEach(1...totalDays, id: \.self) { day in
                CalendarDayView(
                    day: day,
                    isCurrentDay: day == entry.currentDay && month == Calendar.current.component(.month, from: Date()) && year == Calendar.current.component(.year, from: Date()),
                    category: getCategoryForDay(day),
                    month: month,
                    year: year
                )
            }
            // Trailing blanks to fill 6x7 grid
            let filled = firstOffset + totalDays
            let remaining = max(0, (7 * 6) - filled)
            ForEach(0..<remaining, id: \.self) { _ in
                Color.clear
                    .frame(height: 24)
            }
        }
    }

    private func daysIn(month: Int, year: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        let calendar = Calendar.current
        let date = calendar.date(from: comps) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    // 0 for Sunday ... 6 for Saturday
    private func firstWeekdayOffset(month: Int, year: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let calendar = Calendar.current
        let date = calendar.date(from: comps) ?? Date()
        let weekday = calendar.component(.weekday, from: date) // 1..7
        return (weekday - 1)
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
