import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeOnboardingDirectoryFromBackup()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func excludeOnboardingDirectoryFromBackup() {
    let fileManager = FileManager.default
    guard let appSupportDir = fileManager.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first else {
      return
    }
    var onboardingDir = appSupportDir.appendingPathComponent("onboarding", isDirectory: true)
    try? fileManager.createDirectory(at: onboardingDir, withIntermediateDirectories: true)
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    try? onboardingDir.setResourceValues(resourceValues)
  }
}
