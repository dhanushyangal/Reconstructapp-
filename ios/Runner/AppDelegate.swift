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
      case "updateDailyNotesWidget":
        if let args = call.arguments as? [String: Any],
           let noteText = args["noteText"] as? String,
           let noteCount = args["noteCount"] as? Int {
          self.updateDailyNotesWidget(noteText: noteText, noteCount: noteCount)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updateDailyNotesWidget", details: nil))
        }
        
      case "updateWeeklyPlannerWidget":
        if let args = call.arguments as? [String: Any],
           let weekGoals = args["weekGoals"] as? [String],
           let completedTasks = args["completedTasks"] as? Int,
           let totalTasks = args["totalTasks"] as? Int {
          self.updateWeeklyPlannerWidget(weekGoals: weekGoals, completedTasks: completedTasks, totalTasks: totalTasks)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updateWeeklyPlannerWidget", details: nil))
        }
        
      case "updateVisionBoardWidget":
        if let args = call.arguments as? [String: Any],
           let goals = args["goals"] as? [String],
           let motivation = args["motivation"] as? String {
          self.updateVisionBoardWidget(goals: goals, motivation: motivation)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updateVisionBoardWidget", details: nil))
        }
        
      case "updateCalendarWidget":
        if let args = call.arguments as? [String: Any],
           let events = args["events"] as? [String],
           let currentMonth = args["currentMonth"] as? String,
           let daysInMonth = args["daysInMonth"] as? Int {
          self.updateCalendarWidget(events: events, currentMonth: currentMonth, daysInMonth: daysInMonth)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updateCalendarWidget", details: nil))
        }
        
      case "updateAnnualPlannerWidget":
        if let args = call.arguments as? [String: Any],
           let yearGoals = args["yearGoals"] as? [String],
           let completedMilestones = args["completedMilestones"] as? Int,
           let totalMilestones = args["totalMilestones"] as? Int {
          self.updateAnnualPlannerWidget(yearGoals: yearGoals, completedMilestones: completedMilestones, totalMilestones: totalMilestones)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for updateAnnualPlannerWidget", details: nil))
        }
        
             case "refreshAllWidgets":
         WidgetCenter.shared.reloadAllTimelines()
         result(true)
         
       case "configureWidget":
         if let args = call.arguments as? [String: Any],
            let widgetId = args["widgetId"] as? String,
            let theme = args["theme"] as? String,
            let widgetType = args["widgetType"] as? String {
           self.configureWidget(widgetId: widgetId, theme: theme, widgetType: widgetType)
           result(true)
         } else {
           result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for configureWidget", details: nil))
         }
        
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
    
    // Handle deep links (e.g., mentalfitness://dailynotes)
    if url.scheme == "mentalfitness" {
      print("Received deep link: \(url)")
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
  
  // MARK: - Widget Update Methods
  
  private func updateDailyNotesWidget(noteText: String, noteCount: Int) {
    let data = SharedDataModel.DailyNotesData(
      noteText: noteText,
      noteCount: noteCount,
      lastUpdated: Date()
    )
    SharedDataModel.saveDailyNotesData(data)
  }
  
  private func updateWeeklyPlannerWidget(weekGoals: [String], completedTasks: Int, totalTasks: Int) {
    let data = SharedDataModel.WeeklyPlannerData(
      weekGoals: weekGoals,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
      lastUpdated: Date()
    )
    SharedDataModel.saveWeeklyPlannerData(data)
  }
  
  private func updateVisionBoardWidget(goals: [String], motivation: String) {
    let data = SharedDataModel.VisionBoardData(
      goals: goals,
      motivation: motivation,
      lastUpdated: Date()
    )
    SharedDataModel.saveVisionBoardData(data)
  }
  
  private func updateCalendarWidget(events: [String], currentMonth: String, daysInMonth: Int) {
    let data = SharedDataModel.CalendarData(
      events: events,
      currentMonth: currentMonth,
      daysInMonth: daysInMonth,
      lastUpdated: Date()
    )
    SharedDataModel.saveCalendarData(data)
  }
  
     private func updateAnnualPlannerWidget(yearGoals: [String], completedMilestones: Int, totalMilestones: Int) {
     let data = SharedDataModel.AnnualPlannerData(
       yearGoals: yearGoals,
       completedMilestones: completedMilestones,
       totalMilestones: totalMilestones,
       lastUpdated: Date()
     )
     SharedDataModel.saveAnnualPlannerData(data)
   }
   
   private func configureWidget(widgetId: String, theme: String, widgetType: String) {
     let config = SharedDataModel.WidgetConfigData(
       widgetId: widgetId,
       theme: theme,
       widgetType: widgetType,
       lastUpdated: Date()
     )
     SharedDataModel.saveWidgetConfiguration(config)
   }
}
