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
