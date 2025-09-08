import UIKit
import Flutter
import GoogleSignIn
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
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
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(name: "ios_widget_service",
                                              binaryMessenger: controller.binaryMessenger)
    
    widgetChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "updateNotesWidget":
        if let args = call.arguments as? [String: Any],
           let notesDataJson = args["notesData"] as? String,
           let selectedNoteId = args["selectedNoteId"] as? String? {
          
          // Decode notes data
          if let data = notesDataJson.data(using: .utf8) {
            do {
              let notesData = try JSONDecoder().decode([SharedDataModel.NoteData].self, from: data)
              SharedDataModel.saveNotesData(notesData)
              if let noteId = selectedNoteId {
                SharedDataModel.saveSelectedNoteId(noteId)
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
          
      case "updateVisionBoardWidget":
        if let args = call.arguments as? [String: Any],
           let theme = args["theme"] as? String,
           let categories = args["categories"] as? [String],
           let todosByCategoryJson = args["todosByCategoryJson"] as? [String: String] {
          
          SharedDataModel.saveTheme(theme)
          SharedDataModel.saveCategories(categories)
          
          for (category, todosJson) in todosByCategoryJson {
            SharedDataModel.saveTodos(todosJson, for: category, theme: theme)
          }
          
          WidgetCenter.shared.reloadAllTimelines()
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for Vision Board widget", details: nil))
        }
        
      case "refreshAllWidgets":
        WidgetCenter.shared.reloadAllTimelines()
        result(true)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
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
    
    // Handle deep links (e.g., reconstrect://dailynotes, reconstrect://visionboard/theme, etc.)
    if url.scheme == "reconstrect" {
      print("Received deep link: \(url)")
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
}
