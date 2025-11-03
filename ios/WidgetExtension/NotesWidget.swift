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
    let theme: String
    let imagePath: String?
}

struct NotesProvider: TimelineProvider {
    typealias Entry = NotesEntry
    
    func placeholder(in context: Context) -> NotesEntry {
        NotesEntry(
            date: Date(), 
            title: "My Notes",
            content: "Add your notes here",
            theme: "Post-it Daily Notes",
            imagePath: nil
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
        let theme: String = SharedDataModel.getNotesTheme() ?? "Post-it Daily Notes"

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
        let imagePath = chosen?.imagePath
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

        return NotesEntry(date: date, title: title, content: content, theme: theme, imagePath: imagePath)
    }
}

struct NotesWidgetView: View {
    var entry: NotesEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Theme-based background
            themeBackground(for: entry.theme)
            
            let isSmall = (family == .systemSmall)
            let textColor = themeTextColor(for: entry.theme)

            VStack(alignment: .leading, spacing: isSmall ? 6 : 8) {
                if isSmall {
                    // Compact header for small size
                    Text(entry.title)
                        .font(.subheadline)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                } else {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(textColor)
                            .font(.title3)
                        Text(entry.title)
                            .font(.headline)
                            .foregroundColor(textColor)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                
                // Display note image if available
                if let imagePath = entry.imagePath, !imagePath.isEmpty {
                    // Handle both file:// URLs and direct paths
                    let actualPath: String
                    if imagePath.hasPrefix("file://") {
                        actualPath = String(imagePath.dropFirst(7))
                    } else if imagePath.hasPrefix("/") {
                        actualPath = imagePath
                    } else {
                        actualPath = imagePath
                    }
                    
                    // Try to load image from file system
                    if let uiImage = UIImage(contentsOfFile: actualPath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: isSmall ? 60 : 100)
                            .clipped()
                            .cornerRadius(6)
                    } else {
                        // If image not found, show placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: isSmall ? 60 : 100)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(textColor.opacity(0.5))
                            )
                    }
                }

                Text(entry.content)
                    .font(isSmall ? .caption2 : .callout)
                    .lineLimit(isSmall ? 3 : 5)
                    .foregroundColor(textColor.opacity(0.92))
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.9)
                    
                Spacer()

                if !isSmall {
                    HStack {
                        Text("Notes")
                            .font(.caption2)
                            .foregroundColor(textColor.opacity(0.85))
                        Spacer()
                        Link(destination: URL(string: "mentalfitness://notes")!) {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(textColor)
                                .font(.title3)
                        }
                    }
                }
            }
            .padding(isSmall ? 10 : 12)
        }
        .containerBackground(.clear, for: .widget)
    }
    
    // Theme-based background
    @ViewBuilder
    private func themeBackground(for theme: String) -> some View {
        let lowercased = theme.lowercased()
        
        // Box/Boxy Daily Notes - white background
        if lowercased.contains("box") || lowercased.contains("boxy") {
            Color.white
        }
        // Post-it Daily Notes - light green background
        else if lowercased.contains("post-it") || lowercased.contains("postit") {
            Color(red: 0.77, green: 0.88, blue: 0.65) // #C5E1A5
        }
        // Premium Daily Notes - black background
        else if lowercased.contains("premium") {
            Color.black
        }
        // Floral Daily Notes - floral image background
        else if lowercased.contains("floral") {
            GeometryReader { geo in
                ZStack {
                    // Try to load the image using Image() (asset catalog)
                    Image("daily-note")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .overlay(Color.black.opacity(family == .systemSmall ? 0.22 : 0.16))
                }
            }
        }
        // Default to Post-it theme
        else {
            Color(red: 0.77, green: 0.88, blue: 0.65)
        }
    }
    
    // Theme-based text color
    private func themeTextColor(for theme: String) -> Color {
        let lowercased = theme.lowercased()
        
        // Box/Boxy Daily Notes - black text on white background
        if lowercased.contains("box") || lowercased.contains("boxy") {
            return Color(red: 0.13, green: 0.13, blue: 0.13) // Dark text
        }
        // Premium Daily Notes - white text on black background
        else if lowercased.contains("premium") {
            return .white
        }
        // Post-it Daily Notes - dark text on light green background
        else if lowercased.contains("post-it") || lowercased.contains("postit") {
            return Color(red: 0.13, green: 0.13, blue: 0.13) // Dark text
        }
        // Floral Daily Notes - white text on floral background
        else if lowercased.contains("floral") {
            return .white
        }
        // Default: dark text
        else {
            return Color(red: 0.13, green: 0.13, blue: 0.13)
        }
    }
}

struct NotesWidget_Previews: PreviewProvider {
    static var previews: some View {
        NotesWidgetView(entry: NotesEntry(
            date: Date(),
            title: "My Notes",
            content: "This is a sample note content for testing the widget.",
            theme: "Post-it Daily Notes",
            imagePath: nil
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        NotesWidgetView(entry: NotesEntry(
            date: Date(), 
            title: "My Notes",
            content: "This is a longer sample note content for testing the medium size widget. It should show more text.",
            theme: "Premium Daily Notes",
            imagePath: nil
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}


