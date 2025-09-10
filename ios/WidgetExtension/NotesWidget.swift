import WidgetKit
import SwiftUI

struct NotesWidget: Widget {
    let kind: String = "NotesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotesProvider()) { entry in
            NotesWidgetView(entry: entry)
        }
        .configurationDisplayName("Notes")
        .description("Quick access to your notes.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NotesEntry: TimelineEntry {
    let date: Date
    let title: String
    let content: String
}

struct NotesProvider: TimelineProvider {
    typealias Entry = NotesEntry
    
    func placeholder(in context: Context) -> NotesEntry {
        NotesEntry(
            date: Date(), 
            title: "My Notes",
            content: "Add your notes here"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NotesEntry) -> ()) {
        let currentDate = Date()
        let entry = buildEntry(date: currentDate)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NotesEntry>) -> ()) {
        let currentDate = Date()
        let entry = buildEntry(date: currentDate)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // Build entry by reading the shared notes array and selected note id
    private func buildEntry(date: Date) -> NotesEntry {
        let notes: [SharedDataModel.NoteData] = SharedDataModel.getNotesData()
        let selectedId: String? = SharedDataModel.getSelectedNoteId()

        // Choose selected note, otherwise first pinned, otherwise first note
        let chosen: SharedDataModel.NoteData? = {
            if let id = selectedId, let match = notes.first(where: { $0.id == id }) {
                return match
            }
            if let pinned = notes.first(where: { $0.isPinned }) {
                return pinned
            }
            return notes.first
        }()

        let title = chosen?.title ?? "My Notes"
        let content: String = {
            guard let note = chosen else { return "Add your notes here" }
            if !note.checklistItems.isEmpty {
                let lines = note.checklistItems.prefix(4).map { item in
                    let bullet = item.isChecked ? "✓" : "•"
                    return "\(bullet) \(item.text)"
                }
                return lines.joined(separator: "\n")
            }
            if !note.content.isEmpty { return note.content }
            return "Add your notes here"
        }()

        return NotesEntry(date: date, title: title, content: content)
    }
}

struct NotesWidgetView: View {
    var entry: NotesEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("daily-note")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(family == .systemSmall ? 0.22 : 0.16))
            }

            let isSmall = (family == .systemSmall)

            VStack(alignment: .leading, spacing: isSmall ? 6 : 8) {
                if isSmall {
                    // Compact header for small size
                    Text(entry.title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                } else {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(.white)
                            .font(.title3)
                        Text(entry.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                    }
                }

                Text(entry.content)
                    .font(isSmall ? .caption2 : .callout)
                    .lineLimit(isSmall ? 3 : 5)
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.9)
                    
                Spacer()

                if !isSmall {
                    HStack {
                        Text("Notes")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Link(destination: URL(string: "mentalfitness://notes")!) {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                    }
                }
            }
            .padding(isSmall ? 10 : 12)
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct NotesWidget_Previews: PreviewProvider {
    static var previews: some View {
        NotesWidgetView(entry: NotesEntry(
            date: Date(),
            title: "My Notes",
            content: "This is a sample note content for testing the widget."
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        NotesWidgetView(entry: NotesEntry(
            date: Date(), 
            title: "My Notes",
            content: "This is a longer sample note content for testing the medium size widget. It should show more text."
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}


