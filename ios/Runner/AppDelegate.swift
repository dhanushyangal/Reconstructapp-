import UIKit
import Flutter
import GoogleSignIn
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var widgetChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure Google Sign-In
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let clientId = plist["CLIENT_ID"] as? String {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      print("Google Sign-In configured with client ID: \(clientId)")
    } else {
      // Fallback client ID if GoogleService-Info.plist is not found
      let clientId = "633982729642-d6lvv51c28ahcr1g8820a83vka5pb5k9.apps.googleusercontent.com"
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      print("Google Sign-In configured with fallback client ID: \(clientId)")
    }
    
    // Setup widget service channel
    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(
        name: "ios_widget_service",
        binaryMessenger: controller.binaryMessenger
      )
      self.widgetChannel = widgetChannel
      
      widgetChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        
        case "updateNotesWidget":
          if let args = call.arguments as? [String: Any],
             let notesDataJson = args["notesData"] as? String {
            
            let selectedNoteId = args["selectedNoteId"] as? String
            let theme = args["theme"] as? String
            
            if let data = notesDataJson.data(using: .utf8) {
              do {
                let notesData = try JSONDecoder().decode([SharedDataModel.NoteData].self, from: data)
                SharedDataModel.saveNotesData(notesData)
                if let noteId = selectedNoteId {
                  SharedDataModel.saveSelectedNoteId(noteId)
                }
                if let notesTheme = theme {
                  SharedDataModel.saveNotesTheme(notesTheme)
                  print("Notes theme saved: \(notesTheme)")
                }
                WidgetCenter.shared.reloadAllTimelines()
                result(true)
              } catch {
                print("Failed to decode notes data: \(error)")
                result(FlutterError(code: "DECODE_ERROR", message: "Failed to decode notes data", details: nil))
              }
            } else {
              result(FlutterError(code: "INVALID_DATA", message: "Invalid notes data", details: nil))
            }
          } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments for notes widget", details: nil))
          }
          break
          
        case "updateVisionBoardWidget":
          if let args = call.arguments as? [String: Any],
             let theme = args["theme"] as? String,
             let categories = args["categories"] as? [String],
             let todosByCategoryJson = args["todosByCategoryJson"] as? [String: String] {
            
            // Save theme (using same keys as Flutter)
            guard let userDefaults = UserDefaults(suiteName: "group.com.mentalfitness.reconstruct.widgets") else {
              result(FlutterError(code: "STORAGE_ERROR", message: "Failed to access shared storage", details: nil))
              return
            }
            
            userDefaults.set(theme, forKey: "flutter.vision_board_current_theme")
            userDefaults.set(theme, forKey: "vision_board_current_theme")
            userDefaults.set(theme, forKey: "widget_theme") // Fallback
            print("Vision Board theme saved: \(theme)")
            
            // Save full categories list as JSON (for widget to scan all categories)
            if let categoriesJson = try? JSONEncoder().encode(categories),
               let jsonString = String(data: categoriesJson, encoding: .utf8) {
                userDefaults.set(jsonString, forKey: "vision_board_categories")
                userDefaults.set(jsonString, forKey: "flutter.vision_board_categories")
                print("Vision Board Widget: Saved \(categories.count) categories to scan")
            }
            
            // Also save using the old method for compatibility (but only first 5 for old code)
            SharedDataModel.saveCategories(categories)
            
            // Save todos using universal keys (matching Flutter's storage)
            // Flutter uses: vision_board_$category (not theme-specific)
            for (category, todosJson) in todosByCategoryJson {
              userDefaults.set(todosJson, forKey: "vision_board_\(category)")
              userDefaults.set(todosJson, forKey: "flutter.vision_board_\(category)")
              print("Todos for \(category) saved to universal key: vision_board_\(category)")
            }
            
            userDefaults.synchronize()
            WidgetCenter.shared.reloadAllTimelines()
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for Vision Board widget", details: nil))
          }
          break
          
        case "refreshAllWidgets":
          WidgetCenter.shared.reloadAllTimelines()
          result(true)
          break

        case "getCurrentTheme":
          let theme = SharedDataModel.getTheme()
          result(theme ?? "")
          break
          
        case "updateCalendarWidget":
          if let args = call.arguments as? [String: Any],
             let calendarData = args["calendarData"] as? [String: String] {
            
            SharedDataModel.saveCalendarData(calendarData)
            WidgetCenter.shared.reloadAllTimelines()
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for Calendar widget", details: nil))
          }
          break
          
        case "getCalendarData":
          let calendarData = SharedDataModel.getCalendarData()
          result(calendarData)
          break
          
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle URL schemes for Google Sign-In and deep links
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("Received URL: \(url)")
    
    // Handle Google Sign-In URL
    if GIDSignIn.sharedInstance.handle(url) {
      print("Google Sign-In handled URL: \(url)")
      return true
    }
    
    // Handle deep links for widgets
    if url.scheme == "mentalfitness" || url.scheme == "reconstrect" {
      print("Received deep link: \(url)")
      // Example URLs:
      // reconstrect://visionboard/theme
      // reconstrect://visionboard/category-select
      // reconstrect://visionboard/category/<name>
      if url.host == "visionboard" {
        let path = url.path // e.g. /theme, /category-select, /category/<name>
        if path.hasPrefix("/theme") {
          widgetChannel?.invokeMethod("openVisionBoardTheme", arguments: nil)
        } else if path.hasPrefix("/category-select") {
          widgetChannel?.invokeMethod("openVisionBoardCategorySelect", arguments: nil)
        } else if path.hasPrefix("/category/") {
          let categoryName = String(path.dropFirst("/category/".count))
            .removingPercentEncoding
          widgetChannel?.invokeMethod("openVisionBoardCategory", arguments: ["category": categoryName ?? ""])        
        }
        return true
      }
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
}

