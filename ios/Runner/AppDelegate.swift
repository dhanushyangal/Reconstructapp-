import Flutter
import UIKit
import GoogleSignIn

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
    
    // Handle deep links (e.g., reconstrect://dailynotes)
    if url.scheme == "reconstrect" {
      print("Received deep link: \(url)")
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
}
