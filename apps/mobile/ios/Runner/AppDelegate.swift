import Flutter
import UIKit
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static var apnsStatus = "pending"
  private var apnsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Silent APNs is how Firebase verifies the app before sending SMS.
    // Without a delivered token + notification handoff, iOS falls back to
    // reCAPTCHA (Safari), which often sticks on about:blank.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // .unknown lets Firebase pick sandbox vs production from the provisioning profile.
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    let prefix = String(hex.prefix(16))
    AppDelegate.apnsStatus = "ok len=\(deviceToken.count) prefix=\(prefix) env=\(Self.apnsTokenTypeLabel)"
    NSLog("Buildingo APNs token %@", AppDelegate.apnsStatus)
    print("Buildingo APNs token \(AppDelegate.apnsStatus)")
    // Local debug/release installs are development-signed → APNs sandbox.
    // TestFlight / App Store are distribution-signed → APNs production.
    // Using .unknown has mis-detected on newer iOS and caused internal-error.
    Auth.auth().setAPNSToken(deviceToken, type: Self.apnsTokenType)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  /// Development provisioning embeds get-task-allow; App Store / TestFlight do not.
  /// Do not rely on `#if DEBUG` — Flutter device runs can compile native code
  /// without that flag, which previously mis-labeled tokens as production.
  private static var isDevelopmentSigned: Bool {
    guard
      let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
      let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
      let profile = String(data: data, encoding: .ascii)
    else {
      // No embedded profile → App Store build → production APS.
      return false
    }
    return profile.contains("get-task-allow")
  }

  private static var apnsTokenType: AuthAPNSTokenType {
    isDevelopmentSigned ? .sandbox : .prod
  }

  private static var apnsTokenTypeLabel: String {
    isDevelopmentSigned ? "sandbox" : "prod"
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    AppDelegate.apnsStatus = "failed: \(error.localizedDescription)"
    NSLog("Buildingo APNs registration failed: %@", error.localizedDescription)
    print("Buildingo APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    let handled = Auth.auth().canHandleNotification(userInfo)
    let keys = Array(userInfo.keys).map { "\($0)" }.sorted().joined(separator: ",")
    NSLog("Buildingo remote notification authHandled=%@ keys=%@", handled ? "yes" : "no", keys)
    print("Buildingo remote notification authHandled=\(handled) keys=\(keys)")
    if handled {
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }

  // reCAPTCHA callback URL scheme — must reach Firebase Auth.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "buildingo/apns",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "status":
        result(AppDelegate.apnsStatus)
      case "verifyPhone":
        guard let phone = call.arguments as? String, !phone.isEmpty else {
          result(FlutterError(code: "bad-args", message: "phone required", details: nil))
          return
        }
        self?.verifyPhoneNative(phone, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    apnsChannel = channel
  }

  /// Native verify so we can print the full FIRAuth NSError (Flutter strips it).
  private func verifyPhoneNative(_ phone: String, result: @escaping FlutterResult) {
    print("Buildingo native verifyPhone \(phone)")
    PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { verificationID, error in
      if let error = error as NSError? {
        var dump: [String: Any] = [
          "domain": error.domain,
          "code": error.code,
          "localizedDescription": error.localizedDescription,
        ]
        if let name = error.userInfo[AuthErrorUserInfoNameKey] as? String {
          dump["name"] = name
        }
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
          dump["underlyingDomain"] = underlying.domain
          dump["underlyingCode"] = underlying.code
          dump["underlyingDescription"] = underlying.localizedDescription
          if let deserialized = underlying.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] {
            dump["deserialized"] = "\(deserialized)"
          }
          dump["underlyingUserInfo"] = "\(underlying.userInfo)"
        }
        dump["userInfo"] = "\(error.userInfo)"
        print("Buildingo native phone auth error dump: \(dump)")
        result([
          "ok": false,
          "error": dump.mapValues { "\($0)" },
        ])
        return
      }
      print("Buildingo native phone auth ok verificationID len=\(verificationID?.count ?? 0)")
      result([
        "ok": true,
        "verificationId": verificationID as Any,
      ])
    }
  }
}
