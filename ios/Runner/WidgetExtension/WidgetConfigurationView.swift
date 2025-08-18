import SwiftUI
import WidgetKit

struct WidgetConfigurationView: View {
    @State private var selectedTheme: WidgetTheme = .default
    @State private var selectedWidgetType: WidgetType = .dailyNotes
    @State private var showThemeSelection = false
    
    let widgetId: String
    let onConfigure: (WidgetConfiguration) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Image(systemName: getWidgetIcon())
                        .font(.system(size: 50))
                        .foregroundColor(getThemeColor())
                    
                    Text(getWidgetTitle())
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Configure your widget appearance and content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Theme Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme")
                        .font(.headline)
                    
                    Button(action: {
                        showThemeSelection = true
                    }) {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(getThemeColor())
                            
                            Text(selectedTheme.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // Widget Type Selection (for some widgets)
                if selectedWidgetType == .visionBoard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Display Type")
                            .font(.headline)
                        
                        Picker("Display Type", selection: $selectedWidgetType) {
                            Text("Goals & Dreams").tag(WidgetType.visionBoard)
                            Text("Motivation Quotes").tag(WidgetType.visionBoard)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        let config = WidgetConfiguration(
                            widgetId: widgetId,
                            theme: selectedTheme,
                            widgetType: selectedWidgetType
                        )
                        onConfigure(config)
                    }) {
                        Text("Add Widget")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(getThemeColor())
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Cancel configuration
                    }) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .navigationTitle("Widget Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showThemeSelection) {
                ThemeSelectionView(selectedTheme: $selectedTheme)
            }
        }
    }
    
    private func getWidgetIcon() -> String {
        switch selectedWidgetType {
        case .dailyNotes: return "note.text"
        case .weeklyPlanner: return "calendar"
        case .visionBoard: return "eye"
        case .calendar: return "calendar.badge.clock"
        case .annualPlanner: return "calendar.badge.plus"
        }
    }
    
    private func getWidgetTitle() -> String {
        switch selectedWidgetType {
        case .dailyNotes: return "Daily Notes"
        case .weeklyPlanner: return "Weekly Planner"
        case .visionBoard: return "Vision Board"
        case .calendar: return "Annual Calendar"
        case .annualPlanner: return "Annual Planner"
        }
    }
    
    private func getThemeColor() -> Color {
        selectedTheme.color
    }
}

struct ThemeSelectionView: View {
    @Binding var selectedTheme: WidgetTheme
    @Environment(\.presentationMode) var presentationMode
    
    let themes: [WidgetTheme] = [
        .default,
        .postit,
        .premium,
        .watercolor,
        .floral,
        .japanese,
        .box,
        .animal,
        .sport,
        .coffee
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(themes, id: \.self) { theme in
                    Button(action: {
                        selectedTheme = theme
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            // Theme preview
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.color.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: theme.icon)
                                        .foregroundColor(theme.color)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(theme.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(theme.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.color)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Theme")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct WidgetConfiguration {
    let widgetId: String
    let theme: WidgetTheme
    let widgetType: WidgetType
}

enum WidgetTheme: String, CaseIterable {
    case `default` = "default"
    case postit = "postit"
    case premium = "premium"
    case watercolor = "watercolor"
    case floral = "floral"
    case japanese = "japanese"
    case box = "box"
    case animal = "animal"
    case sport = "sport"
    case coffee = "coffee"
    
    var displayName: String {
        switch self {
        case .default: return "Default Theme"
        case .postit: return "Post-it Theme"
        case .premium: return "Premium Theme"
        case .watercolor: return "Watercolor Theme"
        case .floral: return "Floral Theme"
        case .japanese: return "Japanese Theme"
        case .box: return "Box Vision Board"
        case .animal: return "Ruby Reds Vision Board"
        case .sport: return "Winter Warmth Vision Board"
        case .coffee: return "Coffee Hues Vision Board"
        }
    }
    
    var description: String {
        switch self {
        case .default: return "Clean and simple design"
        case .postit: return "Colorful sticky note style"
        case .premium: return "Elegant and sophisticated"
        case .watercolor: return "Soft, artistic watercolor"
        case .floral: return "Beautiful floral patterns"
        case .japanese: return "Minimalist Japanese design"
        case .box: return "Organized box layout"
        case .animal: return "Warm ruby red tones"
        case .sport: return "Cozy winter colors"
        case .coffee: return "Rich coffee-inspired hues"
        }
    }
    
    var color: Color {
        switch self {
        case .default: return .blue
        case .postit: return .yellow
        case .premium: return .purple
        case .watercolor: return .pink
        case .floral: return .green
        case .japanese: return .gray
        case .box: return .orange
        case .animal: return .red
        case .sport: return .blue
        case .coffee: return .brown
        }
    }
    
    var icon: String {
        switch self {
        case .default: return "circle"
        case .postit: return "note.text"
        case .premium: return "star.fill"
        case .watercolor: return "paintbrush"
        case .floral: return "leaf.fill"
        case .japanese: return "mountain.2.fill"
        case .box: return "square.grid.2x2"
        case .animal: return "heart.fill"
        case .sport: return "snowflake"
        case .coffee: return "cup.and.saucer.fill"
        }
    }
}

struct WidgetConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetConfigurationView(
            widgetId: "test",
            onConfigure: { config in
                print("Configured: \(config)")
            }
        )
    }
}
