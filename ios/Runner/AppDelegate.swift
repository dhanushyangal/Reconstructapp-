import UIKit
import Flutter
import GoogleSignIn
import WidgetKit

@main
@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Set up method channel for widget communication
        let controller = window?.rootViewController as! FlutterViewController
        let widgetChannel = FlutterMethodChannel(name: "ios_widget_service", binaryMessenger: controller.binaryMessenger)
        
        widgetChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "updateVisionBoardWidget":
                if let args = call.arguments as? [String: Any],
                   let title = args["title"] as? String,
                   let description = args["description"] as? String,
                   let goals = args["goals"] as? [String] {
                    
                    let visionBoardData = SharedDataModel.VisionBoardData(
                        title: title,
                        description: description,
                        goals: goals,
                        lastUpdated: Date()
                    )
                    SharedDataModel.saveVisionBoardData(visionBoardData)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for VisionBoard widget", details: nil))
                }
                
            case "configureWidget":
                if let args = call.arguments as? [String: Any],
                   let widgetId = args["widgetId"] as? String,
                   let theme = args["theme"] as? String,
                   let widgetType = args["widgetType"] as? String {
                    
                    let config = SharedDataModel.WidgetConfigData(
                        widgetId: widgetId,
                        theme: theme,
                        widgetType: widgetType,
                        lastUpdated: Date()
                    )
                    SharedDataModel.saveWidgetConfiguration(config)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for widget configuration", details: nil))
                }
                
            case "refreshAllWidgets":
                WidgetCenter.shared.reloadAllTimelines()
                result(true)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle Google Sign-In
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // Handle deep links (e.g., mentalfitness://visionboard)
        if url.scheme == "mentalfitness" {
            print("Received deep link: \(url)")
            return true
        }
        
        return super.application(app, open: url, options: options)
    }
}
