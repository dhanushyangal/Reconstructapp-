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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if family == .systemMedium {
                Text(entry.content)
                    .font(.body)
                    .lineLimit(4)
                    .foregroundColor(.secondary)
            } else {
                Text(entry.content)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Text("Notes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                // ✅ Replaced Button with Link for deep linking
                Link(destination: URL(string: "mentalfitness://notes")!) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
        }
        .padding()
        // ✅ Required in iOS 17+ widgets
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
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


